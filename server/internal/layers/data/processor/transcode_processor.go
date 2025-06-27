package processor

import (
	"errors"
	"fmt"
	"os/exec"

	"github.com/gungun974/Melodink/server/internal/logger"
)

func NewTranscodeProcessor() TranscodeProcessor {
	return TranscodeProcessor{}
}

type TranscodeProcessor struct{}

var (
	TranscoderKilledError = errors.New("FFmpeg was killed early")
	TranscoderExitError   = errors.New("FFmpeg exited with non 0 status code")
	TranscoderScanError   = errors.New("Failed to find input format")
)

func (p *TranscodeProcessor) TranscodeLow(
	sourcePath string,
	destinationPath string,
) error {
	return p.transcode([]string{
		"-b:a", "96k",
		"-c:a", "libopus",
		"-vbr", "on",
		"-f", "opus",
	}, sourcePath, destinationPath)
}

func (p *TranscodeProcessor) TranscodeMedium(
	sourcePath string,
	destinationPath string,
) error {
	return p.transcode([]string{
		"-b:a", "128k",
		"-c:a", "libopus",
		"-vbr", "on",
		"-f", "opus",
	}, sourcePath, destinationPath)
}

func (p *TranscodeProcessor) TranscodeHigh(
	sourcePath string,
	destinationPath string,
) error {
	return p.transcode([]string{
		"-b:a", "320k",
		"-c:a", "libopus",
		"-vbr", "on",
		"-f", "opus",
	}, sourcePath, destinationPath)
}

func (*TranscodeProcessor) transcode(
	audioArguments []string,
	sourcePath string,
	destinationPath string,
) error {
	args := []string{}

	args = append(args,
		"-v", "0",
		"-i", sourcePath,
		"-map_metadata", "-1",
		"-map", "0:a:0",
		"-vn",
	)

	args = append(args,
		audioArguments...,
	)

	args = append(args,
		destinationPath,
	)

	logger.TranscoderLogger.Infof(
		"Start transcoding file %s",
		sourcePath,
	)

	cmd := exec.Command("ffmpeg", args...)

	if err := cmd.Start(); err != nil {
		return fmt.Errorf("starting cmd: %w", err)
	}

	var exitErr *exec.ExitError

	switch err := cmd.Wait(); {
	case errors.As(err, &exitErr):
		logger.TranscoderLogger.Infof(
			"Stop transcoding file %s : %v",
			sourcePath,
			err,
		)
		return fmt.Errorf("waiting cmd: %w: %w", err, TranscoderKilledError)
	case err != nil:
		logger.TranscoderLogger.Errorf(
			"Failed transcoding file %s : %v",
			sourcePath,
			err,
		)
		return fmt.Errorf("waiting cmd: %w", err)
	}
	if code := cmd.ProcessState.ExitCode(); code > 1 {
		logger.TranscoderLogger.Errorf(
			"Failed transcoding file %s with an unknow error",
			sourcePath,
		)
		return fmt.Errorf("%w: bbal %d", TranscoderExitError, code)
	}
	logger.TranscoderLogger.Infof(
		"Finish transcoding file %s",
		sourcePath,
	)
	return nil
}
