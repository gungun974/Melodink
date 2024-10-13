package audioimage

import (
	"bytes"
	"errors"
	"io"
	"os"
	"os/exec"

	"github.com/dhowden/tag"
	"github.com/gabriel-vasile/mimetype"
	"github.com/gungun974/Melodink/server/internal/logger"
)

var ErrAudioImageNotFound = errors.New("No image available for this file")

type AudioImage struct {
	MIMEType string
	Data     bytes.Buffer
}

func GetAudioImage(path string) (AudioImage, error) {
	file, err := os.Open(path)
	if err != nil {
		return AudioImage{}, err
	}
	defer file.Close()

	metadata, err := tag.ReadFrom(file)
	if err != nil {
		return AudioImage{}, err
	}

	picture := metadata.Picture()

	if picture != nil {
		return AudioImage{
			MIMEType: picture.MIMEType,
			Data:     *bytes.NewBuffer(picture.Data),
		}, nil
	}

	ffmpeg := exec.Command("ffmpeg", "-v", "quiet",
		"-i", path, "-an", "-vcodec", "copy", "-f", "image2pipe", "-")

	ffmpegOut, err := ffmpeg.StdoutPipe()

	ffmpeg.Stderr = os.Stderr
	if err != nil {
		logger.MainLogger.Errorf(
			"Unable to spin up ffmpeg to decode %v", err,
		)
		return AudioImage{}, ErrAudioImageNotFound
	}
	err = ffmpeg.Start()
	if err != nil {
		logger.MainLogger.Errorf(
			"Unable to spin up ffmpeg to decode %v", err,
		)
		return AudioImage{}, ErrAudioImageNotFound
	}

	alldata, _ := io.ReadAll(ffmpegOut)

	defer ffmpeg.Process.Wait()
	defer ffmpeg.Process.Kill()

	mtype := mimetype.Detect(alldata)

	return AudioImage{
		MIMEType: mtype.String(),
		Data:     *bytes.NewBuffer(alldata),
	}, nil
}
