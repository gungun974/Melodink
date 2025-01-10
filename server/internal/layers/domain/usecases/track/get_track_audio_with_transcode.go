package track_usecase

import (
	"context"
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/gabriel-vasile/mimetype"
	"github.com/gungun974/Melodink/server/internal/helpers"
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

	shouldAddEndOfFileDelemiter := r.Header.Get("X-Melodink-Stream-End-Delimiter")
	timeOffsetRaw := r.Header.Get("X-Melodink-Stream-Offset")

	timeOffset, _ := strconv.Atoi(timeOffsetRaw)

	if quality == AudioTranscodeMax {
		mtype, err := mimetype.DetectFile(track.Path)
		if err != nil {
			return entities.NewInternalError(err)
		}

		w.Header().Set("Content-Type", mtype.String())
		if err := u.transcodeProcessor.TranscodeMax(ctx, time.Duration(timeOffset)*time.Millisecond, track.Path, w); err != nil &&
			!errors.Is(err, processor.TranscoderKilledError) {
			return entities.NewInternalError(err)
		}
	} else if quality == AudioTranscodeHigh {
		w.Header().Set("Content-Type", "audio/flac")
		if err := u.transcodeProcessor.TranscodeHigh(ctx, time.Duration(timeOffset)*time.Millisecond, track.Path, w); err != nil &&
			!errors.Is(err, processor.TranscoderKilledError) {
			return entities.NewInternalError(err)
		}
	} else if quality == AudioTranscodeMedium {
		w.Header().Set("Content-Type", "audio/ogg")
		if err := u.transcodeProcessor.TranscodeMedium(ctx, time.Duration(timeOffset)*time.Millisecond, track.Path, w); err != nil &&
			!errors.Is(err, processor.TranscoderKilledError) {
			return entities.NewInternalError(err)
		}
	} else {
		w.Header().Set("Content-Type", "audio/ogg")
		if err := u.transcodeProcessor.TranscodeLow(ctx, time.Duration(timeOffset)*time.Millisecond, track.Path, w); err != nil &&
			!errors.Is(err, processor.TranscoderKilledError) {
			return entities.NewInternalError(err)
		}
	}

	if !helpers.IsEmptyOrWhitespace(shouldAddEndOfFileDelemiter) {
		_, _ = w.Write([]byte("MelodinkStreamEndOfFile"))
	}

	if f, ok := w.(http.Flusher); ok {
		f.Flush()
	}

	return nil
}
