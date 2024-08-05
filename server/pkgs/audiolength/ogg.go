package audiolength

import (
	"os"
	"time"

	"github.com/jfreymuth/oggvorbis"
)

func getOggDuration(filePath string) (time.Duration, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return 0, err
	}
	defer file.Close()

	// Create a new decoder
	d, err := oggvorbis.NewReader(file)
	if err != nil {
		return 0, err
	}

	// The total duration can be calculated from the length of the data and the sample rate
	totalSamples := d.Length()
	sampleRate := d.SampleRate()
	duration := time.Duration(totalSamples) * time.Second / time.Duration(sampleRate)

	return duration, nil
}
