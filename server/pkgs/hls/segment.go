package hls

import (
	"fmt"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"
)

func GenerateSegments(
	sourcePath string,
	outputPath string,
	segmentLength time.Duration,
	audioArguments []string,
) error {
	cmdFlacOrig := exec.Command("ffmpeg",
		getCommandLineArguments(sourcePath, outputPath, segmentLength, 0, audioArguments)...,
	)

	if output, err := cmdFlacOrig.CombinedOutput(); err != nil {
		err = fmt.Errorf("failed to create HLS segments: %w\nOutput: %s", err, string(output))
		return err
	}

	return nil
}

func getCommandLineArguments(
	sourcePath string,
	outputPath string,
	segmentLength time.Duration,
	startNumber int,
	audioArguments []string,
) []string {
	threads := runtime.GOMAXPROCS(0)

	if threads > 16 {
		threads = 16
	}

	directory := filepath.Dir(outputPath)

	outputFileNameWithoutExtension := strings.TrimSuffix(
		filepath.Base(outputPath),
		filepath.Ext(outputPath),
	)
	outputPrefix := filepath.Join(directory, outputFileNameWithoutExtension)
	outputExtension := ".m4s"
	outputTsArg := outputPrefix + "_%d" + outputExtension

	seekTime := []string{}

	if startNumber > 0 {
		seekTime = append(seekTime, "-ss", formatDuration(
			segmentLength*time.Duration(startNumber),
		))
	}

	maxMuxingQueueSize := 2048 // larger than 128

	args := []string{}

	args = append(args,
		"-analyzeduration", "200M",
		"-probesize", "1G",
	)

	args = append(args,
		seekTime...,
	)

	args = append(args,
		"-i", sourcePath,
		"-map_metadata", "-1",
		"-map_chapters", "-1",
		"-threads", strconv.Itoa(threads),
	)

	args = append(args,
		"-filter_complex", "[0:a]asplit=1[a1]",
		"-map", "[a1]",
	)

	args = append(args,
		audioArguments...,
	)

	args = append(args,
		"-copyts",
		"-avoid_negative_ts", "disabled",
		"-max_muxing_queue_size", strconv.Itoa(maxMuxingQueueSize),
		"-f", "hls",
		"-max_delay", "5000000",
		"-hls_time", strconv.FormatFloat(segmentLength.Seconds(), 'f', -1, 64),
		"-hls_segment_type", "fmp4",

		"-hls_fmp4_init_filename",
		fmt.Sprintf("%s_-1%s", outputFileNameWithoutExtension, outputExtension),

		"-start_number", strconv.Itoa(startNumber),
		"-hls_segment_filename", outputTsArg,
		"-hls_playlist_type", "vod",
		"-hls_list_size", "0",
		"-y", fmt.Sprintf("%s-ffmpeg.m3u8", outputPath),
	)

	return args
}

func formatDuration(d time.Duration) string {
	h := d / time.Hour
	d -= h * time.Hour

	m := d / time.Minute
	d -= m * time.Minute

	s := d / time.Second
	d -= s * time.Second

	ms := d / time.Millisecond

	return fmt.Sprintf("%02d:%02d:%02d.%03d", h, m, s, ms)
}
