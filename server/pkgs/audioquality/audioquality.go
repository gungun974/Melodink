package audioquality

import (
	"context"
	"errors"
	"strconv"
	"time"

	"gopkg.in/vansante/go-ffprobe.v2"
)

type AudioQuality struct {
	SampleRate       int
	BitRate          *int
	BitsPerRawSample *int
}

var ErrAudioStreamNotFound = errors.New("Audio stream was not found")

var ErrCantGetAudioStreamSampleRate = errors.New(
	"Failed to get the SampleRate of the first audio stream",
)

func GetAudioQuality(path string) (AudioQuality, error) {
	ctx, cancelFn := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancelFn()

	data, err := ffprobe.ProbeURL(ctx, path)
	if err != nil {
		return AudioQuality{}, err
	}

	for _, stream := range data.Streams {
		if stream.CodecType != "audio" {
			continue
		}

		sampleRate, err := strconv.Atoi(stream.SampleRate)
		if err != nil {
			return AudioQuality{}, ErrCantGetAudioStreamSampleRate
		}

		var bitrate *int

		if rawBitrate, err := strconv.Atoi(stream.BitRate); err == nil {
			bitrate = &rawBitrate
		}

		var bitsPerRawSample *int

		if rawBitsPerRawSample, err := strconv.Atoi(stream.BitsPerRawSample); err == nil {
			bitsPerRawSample = &rawBitsPerRawSample
		}

		return AudioQuality{
			SampleRate:       sampleRate,
			BitRate:          bitrate,
			BitsPerRawSample: bitsPerRawSample,
		}, nil
	}

	return AudioQuality{}, ErrAudioStreamNotFound
}
