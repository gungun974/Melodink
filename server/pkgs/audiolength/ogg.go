package audiolength

import (
	"bytes"
	"errors"
	"io"
	"os"
	"time"

	"github.com/jfreymuth/oggvorbis"
	"github.com/pion/opus/pkg/oggreader"
)

func getOggVorbisDuration(filePath string) (time.Duration, error) {
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

func getOggOpusDuration(filePath string) (time.Duration, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return 0, err
	}
	defer file.Close()

	// Create a new decoder
	ogg, header, err := oggreader.NewWith(file)
	if err != nil {
		return 0, err
	}

	var totalGranulePosition uint64

	for {
		segments, pageHeader, err := ogg.ParseNextPage()

		if errors.Is(err, io.EOF) {
			break
		} else if bytes.HasPrefix(segments[0], []byte("OpusTags")) {
			continue
		}

		if err != nil {
			return 0, err
		}

		totalGranulePosition = pageHeader.GranulePosition
	}

	// The total duration can be calculated from the length of the data and the sample rate
	totalSamples := totalGranulePosition
	sampleRate := int(header.SampleRate)
	duration := time.Duration(totalSamples) * time.Second / time.Duration(sampleRate)

	return duration, nil
}
