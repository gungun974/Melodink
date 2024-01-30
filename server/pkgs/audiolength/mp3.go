package audiolength

import (
	"io"
	"os"
	"time"

	"github.com/tcolgate/mp3"
)

func getMp3Duration(filePath string) (time.Duration, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return 0, err
	}
	defer file.Close()

	decoder := mp3.NewDecoder(file)
	var duration time.Duration
	var frame mp3.Frame

	for {
		eh := 0
		if err := decoder.Decode(&frame, &eh); err != nil {
			if err == io.EOF {
				break
			}
			return 0, err
		}
		duration += frame.Duration()
	}

	return duration, nil
}
