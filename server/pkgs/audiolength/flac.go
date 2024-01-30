package audiolength

import (
	"os"
	"time"

	"github.com/mewkiz/flac"
)

func getFlacDuration(filePath string) (time.Duration, error) {
	// Open the FLAC file
	f, err := os.Open(filePath)
	if err != nil {
		return 0, err
	}
	defer f.Close()

	// Parse the FLAC file
	stream, err := flac.Parse(f)
	if err != nil {
		return 0, err
	}

	// Calculate the duration
	totalSamples := stream.Info.NSamples
	sampleRate := stream.Info.SampleRate
	duration := time.Duration(totalSamples) * time.Second / time.Duration(sampleRate)

	return duration, nil
}
