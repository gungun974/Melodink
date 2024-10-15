package audiolength

import (
	"context"
	"errors"
	"strconv"
	"time"

	"gopkg.in/vansante/go-ffprobe.v2"
)

var ErrAudioStreamNotFound = errors.New("Audio stream was not found")

var ErrCantGetAudioStreamDuration = errors.New(
	"Failed to get the Duration of the first audio stream",
)

func GetAudioDuration(path string) (int, error) {
	ctx, cancelFn := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancelFn()

	data, err := ffprobe.ProbeURL(ctx, path)
	if err != nil {
		return 0, err
	}

	for _, stream := range data.Streams {
		if stream.CodecType != "audio" {
			continue
		}

		durationS, err := strconv.ParseFloat(stream.Duration, 64)
		if err != nil {
			return 0, ErrCantGetAudioStreamDuration
		}

		return int(durationS * 1000), nil
	}

	return 0, ErrAudioStreamNotFound
}
