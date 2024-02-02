package processor_impl

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strconv"

	"gungun974.com/melodink-server/internal/layers/domain/entities"
	processor "gungun974.com/melodink-server/internal/layers/domain/processors"
)

func NewAudioProcessor() processor.AudioProcessor {
	return &AudioProcessorImpl{}
}

type AudioProcessorImpl struct{}

func CopyFile(src string, dst string) error {
	sourceFile, err := os.Open(src)
	if err != nil {
		return err
	}
	defer sourceFile.Close()

	destFile, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer destFile.Close()

	_, err = io.Copy(destFile, sourceFile)
	if err != nil {
		return err
	}

	return destFile.Sync()
}

func (*AudioProcessorImpl) GenerateFile(source string, destination string) (string, error) {
	mainFile := "audio" + filepath.Ext(source)

	if _, err := os.Stat(path.Join(destination, mainFile)); err == nil {
		return mainFile, nil
	}

	err := os.MkdirAll(destination, 0o755)
	if err != nil {
		return "", err
	}

	targetfile := path.Join(destination, mainFile)

	err = CopyFile(source, targetfile)
	if err != nil {
		return "", err
	}

	return mainFile, nil
}

const segmentDuration = 15

func (*AudioProcessorImpl) GenerateHLS(source string, quality entities.AudioStreamQuality, destination string) (string, error) {
	if _, err := os.Stat(path.Join(destination, "audio.m3u8")); err == nil {
		return "audio.m3u8", nil
	}

	err := os.MkdirAll(destination, 0o755)
	if err != nil {
		return "", err
	}

	currentPath, err := os.Getwd()
	if err != nil {
		return "", err
	}

	var codec string
	var sampleFormat string
	var bitrate string
	var sampleRate string

	switch quality {
	case entities.AudioStreamLowQuality:
		codec = "aac"
		bitrate = "96k"
	case entities.AudioStreamMediumQuality:
		codec = "aac"
		bitrate = "320k"
	case entities.AudioStreamHighQuality:
		codec = "flac"
		sampleRate = "44100"
	case entities.AudioStreamMaxQuality:
		codec = "flac"
	}

	ffmpegArgs := []string{
		"-i", path.Join(currentPath, source),
		"-vn", // Disble video output
	}

	if len(codec) > 0 {
		ffmpegArgs = append(ffmpegArgs, []string{
			"-acodec", codec, // Audio codec
		}...)
	}

	if len(sampleFormat) > 0 {
		ffmpegArgs = append(ffmpegArgs, []string{
			"-sample_fmt", sampleFormat, // Sample format
		}...)
	}

	if len(bitrate) > 0 {
		ffmpegArgs = append(ffmpegArgs, []string{
			"-b:a", bitrate, // Bitrate
		}...)
	}

	if len(sampleRate) > 0 {
		ffmpegArgs = append(ffmpegArgs, []string{
			"-ar", sampleRate, // Sample Rate
		}...)
	}

	ffmpegArgs = append(ffmpegArgs, []string{
		"-hls_time", strconv.Itoa(segmentDuration), // duration of each segment in seconds
		"-hls_list_size", "0", // keep all segments in the playlist
		"-hls_segment_type", "fmp4",
		"-hls_segment_filename", "audio_%03d.m4s",
		"-f", "hls", // Specify HLS output
		path.Join(destination, "audio.m3u8"),
	}...)

	ffmpegCmd := exec.Command(
		"ffmpeg",
		ffmpegArgs...,
	)

	ffmpegCmd.Dir = destination

	output, err := ffmpegCmd.CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("failed to create HLS: %w\nOutput: %s", err, string(output))
	}

	return "audio.m3u8", nil
}

func (*AudioProcessorImpl) GenerateDASH(source string, quality entities.AudioStreamQuality, destination string) (string, error) {
	if _, err := os.Stat(path.Join(destination, "audio.mpd")); err == nil {
		return "audio.mpd", nil
	}

	err := os.MkdirAll(destination, 0o755)
	if err != nil {
		return "", err
	}

	currentPath, err := os.Getwd()
	if err != nil {
		return "", err
	}

	var codec string
	var sampleFormat string
	var bitrate string
	var sampleRate string

	switch quality {
	case entities.AudioStreamLowQuality:
		codec = "aac"
		bitrate = "96k"
	case entities.AudioStreamMediumQuality:
		codec = "aac"
		bitrate = "320k"
	case entities.AudioStreamHighQuality:
		codec = "flac"
		sampleRate = "44100"
	case entities.AudioStreamMaxQuality:
		codec = "flac"
	}

	ffmpegArgs := []string{
		"-i", path.Join(currentPath, source),
		"-vn", // Disble video output
	}

	if len(codec) > 0 {
		ffmpegArgs = append(ffmpegArgs, []string{
			"-acodec", codec, // Audio codec
		}...)
	}

	if len(sampleFormat) > 0 {
		ffmpegArgs = append(ffmpegArgs, []string{
			"-sample_fmt", sampleFormat, // Sample format
		}...)
	}

	if len(bitrate) > 0 {
		ffmpegArgs = append(ffmpegArgs, []string{
			"-b:a", bitrate, // Bitrate
		}...)
	}

	if len(sampleRate) > 0 {
		ffmpegArgs = append(ffmpegArgs, []string{
			"-ar", sampleRate, // Sample Rate
		}...)
	}

	ffmpegArgs = append(ffmpegArgs, []string{
		"-f", "dash", // Specify DASH output
		path.Join(destination, "audio.mpd"),
	}...)

	ffmpegCmd := exec.Command(
		"ffmpeg",
		ffmpegArgs...,
	)

	ffmpegCmd.Dir = destination

	output, err := ffmpegCmd.CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("failed to create DASH: %w\nOutput: %s", err, string(output))
	}

	return "audio.mpd", nil
}
