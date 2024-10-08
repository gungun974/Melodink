package audiolength

import (
	"errors"
	"os"
	"path/filepath"
	"time"

	"github.com/dhowden/tag"
	"github.com/gungun974/Melodink/server/internal/logger"
)

var ErrUnsupportedAudioFormat = errors.New("Unsupported Audio Format")

func GetAudioDuration(path string) (int, error) {
	file, err := os.Open(path)
	if err != nil {
		return 0, err
	}
	defer file.Close()

	metadata, err := tag.ReadFrom(file)
	if err != nil {
		return 0, err
	}

	fileType := metadata.FileType()

	duration := time.Duration(0)

	if filepath.Ext(path) == ".m4a" {
		fileType = tag.M4A
	}

	switch fileType {
	case tag.MP3:
		duration, err = getMp3Duration(path)
	case tag.OGG:
		duration, err = getOggDuration(path)
	case tag.M4A:
		duration, err = getM4aDuration(path)
	case tag.FLAC:
		duration, err = getFlacDuration(path)
	default:
		logger.MainLogger.Warnf(
			"An unsupported audio format have been pass to audiolength : %s",
			fileType,
		)
		return 0, ErrUnsupportedAudioFormat
	}

	if err != nil {
		return 0, err
	}

	return int(duration.Milliseconds()), nil
}
