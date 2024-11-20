package hls

import (
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/gungun974/Melodink/server/pkgs/audiolength"
)

func computeEqualLengthSegments(
	desiredSegmentLength time.Duration,
	totalRuntime time.Duration,
) ([]float64, error) {
	if desiredSegmentLength <= 0 || totalRuntime <= 0 {
		return nil, fmt.Errorf(
			"invalid segment length (%v) or runtime (%v)",
			desiredSegmentLength,
			totalRuntime,
		)
	}

	wholeSegments := totalRuntime / desiredSegmentLength
	remainingDuration := totalRuntime % desiredSegmentLength

	segmentsLen := int(wholeSegments)
	if remainingDuration > 0 {
		segmentsLen++
	}

	segments := make([]float64, segmentsLen)
	for i := 0; i < int(wholeSegments); i++ {
		segments[i] = desiredSegmentLength.Seconds()
	}

	if remainingDuration > 0 {
		segments[len(segments)-1] = remainingDuration.Seconds()
	}

	return segments, nil
}

func GeneratePlaylist(
	sourcePath string,
	desiredSegmentLength time.Duration,
	name string,
) (string, error) {
	rawTotalRuntime, err := audiolength.GetAudioDuration(sourcePath)
	if err != nil {
		return "", err
	}

	totalRuntime := time.Duration(rawTotalRuntime) * time.Millisecond

	segments, err := computeEqualLengthSegments(desiredSegmentLength, totalRuntime)
	if err != nil {
		return "", err
	}

	isHlsInFmp4 := true

	segmentExtension := ".m4s"

	hlsVersion := "7"
	if !isHlsInFmp4 {
		hlsVersion = "3"
	}

	var maxDuration float64
	if len(segments) > 0 {
		for _, seg := range segments {
			if seg > maxDuration {
				maxDuration = seg
			}
		}
	} else {
		maxDuration = desiredSegmentLength.Seconds()
	}

	var builder strings.Builder
	builder.Grow(128)

	builder.WriteString("#EXTM3U\n")
	builder.WriteString("#EXT-X-PLAYLIST-TYPE:VOD\n")
	fmt.Fprintf(&builder, "#EXT-X-VERSION:%s\n", hlsVersion)
	fmt.Fprintf(&builder, "#EXT-X-TARGETDURATION:%d\n", int(math.Ceil(maxDuration)))
	builder.WriteString("#EXT-X-MEDIA-SEQUENCE:0\n")

	if isHlsInFmp4 {
		fmt.Fprintf(
			&builder,
			"#EXT-X-MAP:URI=\"%s_-1%s\"\n",
			name,
			segmentExtension,
		)
	}

	currentRuntime := time.Duration(0)
	for i, length := range segments {
		lengthDuration := time.Duration(float64(time.Second) * length)
		fmt.Fprintf(&builder, "#EXTINF:%.6f, nodesc\n", length)
		fmt.Fprintf(&builder, "%s_%d%s\n",
			name, i, segmentExtension,
		)
		currentRuntime += lengthDuration
	}

	builder.WriteString("#EXT-X-ENDLIST\n")

	return builder.String(), nil
}
