package processor

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strconv"
	"sync"
	"time"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/pkgs/hls"
)

func NewHlsProcessor() HlsProcessor {
	return HlsProcessor{}
}

type HlsProcessor struct{}

const (
	HLS_STORAGE = "./data/hls/"
	CHUNK_TIME  = time.Second * 3
)

func (p *HlsProcessor) GenerateAdaptativeStream(track *entities.Track) error {
	directory := fmt.Sprintf(
		"%s/%d/",
		HLS_STORAGE,
		track.Id,
	)

	err := os.MkdirAll(directory, 0o755)
	if err != nil {
		return err
	}

	if _, err := os.Stat(path.Join(directory, "master.m3u8")); err == nil {
		return nil
	}

	channels, originalBitrate, err := getAudioInfo(track.Path)
	if err != nil {
		channels = 2
		originalBitrate = 0
	}

	flac44kBitrate := 400000 * channels

	if originalBitrate == 0 {
		originalBitrate = 500000 * channels
	}

	content := fmt.Sprintf(`#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=96000,CODECS="mp4a.40.2",CHANNELS="%d"
96k.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=320000,CODECS="mp4a.40.2",CHANNELS="%d"
320k.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=%d,CODECS="flac",CHANNELS="%d"
flac_44k.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=%d,CODECS="flac",CHANNELS="%d"
flac_orig.m3u8`, channels, channels, flac44kBitrate, channels, originalBitrate, channels)

	outputPath := filepath.Join(directory, "master.m3u8")
	err = os.WriteFile(outputPath, []byte(content), 0o644)
	if err != nil {
		return err
	}

	var wg sync.WaitGroup
	errChan := make(chan error, 4)

	// 96k AAC Stream
	wg.Add(1)
	go func() {
		defer wg.Done()
		err := p.Generate96Stream(track)
		if err != nil {
			errChan <- err
		}
	}()

	// 320k AAC Stream
	wg.Add(1)
	go func() {
		defer wg.Done()
		err := p.Generate320Stream(track)
		if err != nil {
			errChan <- err
		}
	}()

	// FLAC 44.1kHz Stream
	wg.Add(1)
	go func() {
		defer wg.Done()
		err := p.Generate44kStream(track)
		if err != nil {
			errChan <- err
		}
	}()

	// Original FLAC Stream
	wg.Add(1)
	go func() {
		defer wg.Done()
		err := p.GenerateMaxStream(track)
		if err != nil {
			errChan <- err
		}
	}()

	go func() {
		wg.Wait()
		close(errChan)
	}()

	for err := range errChan {
		logger.MainLogger.Error(err)
		return err
	}

	return nil
}

func (p *HlsProcessor) Generate96Stream(track *entities.Track) error {
	return p.generateStream(track, "96k", []string{"-c:a", "aac", "-b:a", "96k"})
}

func (p *HlsProcessor) Generate320Stream(track *entities.Track) error {
	return p.generateStream(track, "320k", []string{"-c:a", "aac", "-b:a", "320k"})
}

func (p *HlsProcessor) Generate44kStream(track *entities.Track) error {
	return p.generateStream(track, "flac_44k", []string{"-c:a", "flac", "-ar", "44100"})
}

func (p *HlsProcessor) GenerateMaxStream(track *entities.Track) error {
	return p.generateStream(track, "flac_orig", []string{"-c:a", "flac"})
}

func (p *HlsProcessor) generateStream(
	track *entities.Track,
	outputName string,
	audioArguments []string,
) error {
	directory := fmt.Sprintf(
		"%s/%d/",
		HLS_STORAGE,
		track.Id,
	)

	err := os.MkdirAll(directory, 0o755)
	if err != nil {
		return err
	}

	_ = p.MarkStreamUse(track)

	if _, err := os.Stat(path.Join(directory, outputName+".txt")); err == nil {
		return nil
	}

	_ = touch(filepath.Join(directory, outputName+".txt"))

	playlist, err := hls.GeneratePlaylist(
		track.Path,
		CHUNK_TIME,
		outputName,
	)
	if err != nil {
		logger.MainLogger.Error(err)
		return err
	}

	err = os.WriteFile(filepath.Join(directory, outputName+".m3u8"), []byte(playlist), 0o644)
	if err != nil {
		logger.MainLogger.Error(err)
		return err
	}

	err = hls.GenerateSegments(
		track.Path,
		filepath.Join(directory, outputName),
		CHUNK_TIME,
		audioArguments,
	)
	if err != nil {
		logger.MainLogger.Error(err)
		return err
	}

	return nil
}

func (p *HlsProcessor) CheckStreamSectionReady(
	track *entities.Track,
	outputName string,
	section int,
) bool {
	directory := fmt.Sprintf(
		"%s/%d/",
		HLS_STORAGE,
		track.Id,
	)

	if _, err := os.Stat(path.Join(directory, fmt.Sprintf("%s-ffmpeg.m3u8", outputName))); err == nil {
		return true
	}

	if _, err := os.Stat(path.Join(directory, fmt.Sprintf("%s_%d.m4s", outputName, section))); err != nil {
		return false
	}

	if _, err := os.Stat(path.Join(directory, fmt.Sprintf("%s_%d.m4s", outputName, section+1))); err == nil {
		return true
	}

	return false
}

func getAudioInfo(inputFile string) (int, int, error) {
	cmd := exec.Command("ffprobe",
		"-v", "error",
		"-select_streams", "a:0",
		"-show_entries", "stream=channels:format=bit_rate",
		"-of", "json=compact=1",
		inputFile)

	output, err := cmd.Output()
	if err != nil {
		return 0, 0, fmt.Errorf("ffprobe error: %w", err)
	}

	type FFProbeOutput struct {
		Streams []struct {
			Channels int `json:"channels"`
		} `json:"streams"`
		Format struct {
			BitRate string `json:"bit_rate"`
		} `json:"format"`
	}

	var probeData FFProbeOutput
	if err := json.Unmarshal(output, &probeData); err != nil {
		return 0, 0, fmt.Errorf("failed to parse ffprobe output: %w", err)
	}

	bitrate, err := strconv.Atoi(probeData.Format.BitRate)
	if err != nil {
		return 0, 0, fmt.Errorf("bitrate conversion error: %w", err)
	}

	return probeData.Streams[0].Channels, bitrate, nil
}

func (p *HlsProcessor) CleanOldStreams() error {
	err := os.MkdirAll(HLS_STORAGE, 0o755)
	if err != nil {
		return err
	}

	directories, err := os.ReadDir(HLS_STORAGE)
	if err != nil {
		return err
	}

	for _, directory := range directories {
		if !directory.IsDir() {
			continue
		}

		stat, err := os.Stat(path.Join(HLS_STORAGE, directory.Name(), "use.txt"))
		if err != nil {
			continue
		}

		if time.Since(stat.ModTime()).Hours() < 2 {
			continue
		}

		os.RemoveAll(path.Join(HLS_STORAGE, directory.Name()))
	}

	return nil
}

func (p *HlsProcessor) MarkStreamUse(
	track *entities.Track,
) error {
	directory := fmt.Sprintf(
		"%s/%d/",
		HLS_STORAGE,
		track.Id,
	)
	err := os.MkdirAll(directory, 0o755)
	if err != nil {
		return err
	}

	err = touch(filepath.Join(directory, "use.txt"))
	if err != nil {
		return err
	}

	return nil
}

func touch(path string) error {
	file, err := os.Create(path)
	if err != nil {
		return err
	}
	file.Close()

	time := time.Now()
	err = os.Chtimes(path, time, time)
	if err != nil {
		return err
	}

	return nil
}
