package track_usecase

import (
	"context"
	"errors"
	"io"
	"net/http"
	"strconv"
	"time"

	"github.com/gabriel-vasile/mimetype"
	"github.com/gungun974/Melodink/server/internal/layers/data/processor"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type AudioTranscodeQuality string

const (
	AudioTranscodeMax    AudioTranscodeQuality = "max"
	AudioTranscodeHigh   AudioTranscodeQuality = "high"
	AudioTranscodeMedium AudioTranscodeQuality = "medium"
	AudioTranscodeLow    AudioTranscodeQuality = "low"
)

func (u *TrackUsecase) GetTrackAudioWithTranscode(
	ctx context.Context,
	trackId int,
	quality AudioTranscodeQuality,
	w http.ResponseWriter, r *http.Request,
) error {
	track, err := u.trackRepository.GetTrack(trackId)
	if err != nil {
		if errors.Is(err, repository.TrackNotFoundError) {
			return entities.NewNotFoundError("Track not found")
		}
		return entities.NewInternalError(err)
	}

	timeOffsetRaw := r.Header.Get("X-Melodink-Stream-Offset")

	timeOffset, _ := strconv.Atoi(timeOffsetRaw)

	// wi := NewThrottledWriter(w, 512, 10*time.Millisecond)

	wi := w

	if quality == AudioTranscodeMax {
		mtype, err := mimetype.DetectFile(track.Path)
		if err != nil {
			return entities.NewInternalError(err)
		}

		w.Header().Set("Content-Type", mtype.String())
		if err := u.transcodeProcessor.TranscodeMax(ctx, time.Duration(timeOffset)*time.Millisecond, track.Path, wi); err != nil &&
			!errors.Is(err, processor.TranscoderKilledError) {
			return entities.NewInternalError(err)
		}
	} else if quality == AudioTranscodeHigh {
		w.Header().Set("Content-Type", "audio/flac")
		if err := u.transcodeProcessor.TranscodeHigh(ctx, time.Duration(timeOffset)*time.Millisecond, track.Path, wi); err != nil &&
			!errors.Is(err, processor.TranscoderKilledError) {
			return entities.NewInternalError(err)
		}
	} else if quality == AudioTranscodeMedium {
		w.Header().Set("Content-Type", "audio/ogg")
		if err := u.transcodeProcessor.TranscodeMedium(ctx, time.Duration(timeOffset)*time.Millisecond, track.Path, wi); err != nil &&
			!errors.Is(err, processor.TranscoderKilledError) {
			return entities.NewInternalError(err)
		}
	} else {
		w.Header().Set("Content-Type", "audio/ogg")
		if err := u.transcodeProcessor.TranscodeLow(ctx, time.Duration(timeOffset)*time.Millisecond, track.Path, wi); err != nil &&
			!errors.Is(err, processor.TranscoderKilledError) {
			return entities.NewInternalError(err)
		}
	}

	if f, ok := w.(http.Flusher); ok {
		f.Flush()
	}

	return nil
}

// ThrottledWriter limite le débit des écritures à 512 octets par seconde.
type ThrottledWriter struct {
	Writer        io.Writer
	BytesPerChunk int
	SleepDuration time.Duration
}

// Write implémente l'interface io.Writer et limite les écritures.
func (t *ThrottledWriter) Write(p []byte) (n int, err error) {
	totalWritten := 0
	for len(p) > 0 {
		// Détermine la taille du prochain chunk
		chunkSize := t.BytesPerChunk
		if len(p) < chunkSize {
			chunkSize = len(p)
		}

		// Écrire le chunk courant
		written, err := t.Writer.Write(p[:chunkSize])
		totalWritten += written
		n += written
		if err != nil {
			return n, err
		}

		// Décale le pointeur dans les données
		p = p[written:]

		// Sleep uniquement si des données restent à écrire
		if len(p) > 0 {
			time.Sleep(t.SleepDuration)
		}
	}
	return totalWritten, nil
}

// NewThrottledWriter retourne une instance de ThrottledWriter.
func NewThrottledWriter(
	w io.Writer,
	bytesPerChunk int,
	sleepDuration time.Duration,
) *ThrottledWriter {
	return &ThrottledWriter{
		Writer:        w,
		BytesPerChunk: bytesPerChunk,
		SleepDuration: sleepDuration,
	}
}
