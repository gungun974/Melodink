package audiolength

import (
	"fmt"
	"time"

	"github.com/alfg/mp4"
)

func getM4aDuration(filePath string) (time.Duration, error) {
	info, err := mp4.Open(filePath)
	if err != nil {
		return 0, err
	}

	for _, track := range info.Moov.Traks {
		if track.Mdia.Hdlr.Handler == "soun" { // Look for the sound (audio) handler type
			duration := float64(track.Mdia.Mdhd.Duration) / float64(track.Mdia.Mdhd.Timescale)
			return time.Duration(duration * float64(time.Second)), nil
		}
	}

	return 0, fmt.Errorf("no audio track found")
}
