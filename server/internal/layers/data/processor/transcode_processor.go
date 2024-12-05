package processor

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os/exec"
	"time"

	"github.com/gungun974/Melodink/server/internal/logger"
)

func NewTranscodeProcessor() TranscodeProcessor {
	return TranscodeProcessor{}
}

type TranscodeProcessor struct{}

var (
	TranscoderKilledError = errors.New("FFmpeg was killed early")
	TranscoderExitError   = errors.New("FFmpeg exited with non 0 status code")
)

func (p *TranscodeProcessor) TranscodeLow(
	ctx context.Context,
	seek time.Duration,
	sourcePath string,
	out io.Writer,
) error {
	return p.transcode(ctx, seek, []string{
		"-b:a", "96k",
		"-c:a", "libopus",
		"-vbr", "on",
		"-f", "opus",
	}, sourcePath, out)
}

func (p *TranscodeProcessor) TranscodeMedium(
	ctx context.Context,
	seek time.Duration,
	sourcePath string,
	out io.Writer,
) error {
	return p.transcode(ctx, seek, []string{
		"-b:a", "320k",
		"-c:a", "libopus",
		"-vbr", "on",
		"-f", "opus",
	}, sourcePath, out)
}

func (p *TranscodeProcessor) TranscodeHigh(
	ctx context.Context,
	seek time.Duration,
	sourcePath string,
	out io.Writer,
) error {
	return p.transcode(ctx, seek, []string{
		"-c:a", "flac",
		"-ar", "44100",
		"-f", "flac",
	}, sourcePath, out)
}

func (p *TranscodeProcessor) TranscodeMax(
	ctx context.Context,
	seek time.Duration,
	sourcePath string,
	out io.Writer,
) error {
	return p.transcode(ctx, seek, []string{
		"-c:a", "flac",
		"-f", "flac",
	}, sourcePath, out)
}

func (*TranscodeProcessor) transcode(
	ctx context.Context,
	seek time.Duration,
	audioArguments []string,
	sourcePath string,
	out io.Writer,
) error {
	args := []string{}

	args = append(args,
		"-v", "0",
		"-accurate_seek",
		"-ss", fmt.Sprintf("%dus", seek.Microseconds()),
		"-i", sourcePath,
		"-map", "0:a:0",
		"-vn",
	)

	args = append(args,
		audioArguments...,
	)

	args = append(args,
		"-",
	)

	logger.TranscoderLogger.Infof(
		"Start transcoding file %s at %d",
		sourcePath,
		seek.Milliseconds(),
	)
	cmd := exec.CommandContext(ctx, "ffmpeg", args...)
	cmd.Stdout = out

	if err := cmd.Start(); err != nil {
		return fmt.Errorf("starting cmd: %w", err)
	}

	var exitErr *exec.ExitError

	switch err := cmd.Wait(); {
	case errors.As(err, &exitErr):
		logger.TranscoderLogger.Infof(
			"Stop transcoding file %s at %d : %v",
			sourcePath,
			seek.Milliseconds(),
			err,
		)
		return fmt.Errorf("waiting cmd: %w: %w", err, TranscoderKilledError)
	case err != nil:
		logger.TranscoderLogger.Errorf(
			"Failed transcoding file %s at %d : %v",
			sourcePath,
			seek.Milliseconds(),
			err,
		)
		return fmt.Errorf("waiting cmd: %w", err)
	}
	if code := cmd.ProcessState.ExitCode(); code > 1 {
		logger.TranscoderLogger.Errorf(
			"Failed transcoding file %s at %d with an unknow error",
			sourcePath,
			seek.Milliseconds(),
		)
		return fmt.Errorf("%w: bbal %d", TranscoderExitError, code)
	}
	logger.TranscoderLogger.Infof(
		"Finish transcoding file %s at %d",
		sourcePath,
		seek.Milliseconds(),
	)
	return nil
}
