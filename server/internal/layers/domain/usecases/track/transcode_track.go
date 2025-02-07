package track_usecase

import (
	"context"
	"errors"
	"fmt"
	"path"
	"sync"

	"github.com/gungun974/Melodink/server/internal/layers/data/processor"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
)

type AudioTranscodeQuality string

const (
	AudioTranscodeHigh   AudioTranscodeQuality = "high"
	AudioTranscodeMedium AudioTranscodeQuality = "medium"
	AudioTranscodeLow    AudioTranscodeQuality = "low"
)

var transcodeLocks sync.Map

func getTranscodeLock(trackId int, quality AudioTranscodeQuality) *sync.Mutex {
	key := fmt.Sprintf("%d-%s", trackId, quality)

	actual, exists := transcodeLocks.Load(key)
	if exists {
		return actual.(*sync.Mutex)
	}

	mutex := &sync.Mutex{}
	actual, _ = transcodeLocks.LoadOrStore(key, mutex)
	return actual.(*sync.Mutex)
}

func (u *TrackUsecase) TranscodeTrack(
	ctx context.Context,
	trackId int,
	quality AudioTranscodeQuality,
) error {
	track, err := u.trackRepository.GetTrack(trackId)
	if err != nil {
		if errors.Is(err, repository.TrackNotFoundError) {
			return entities.NewNotFoundError("Track not found")
		}
		return entities.NewInternalError(err)
	}

	lock := getTranscodeLock(trackId, quality)

	lock.Lock()
	defer lock.Unlock()

	transcodingDirectory, err := u.transcodeStorage.GetTrackTranscodeDirectory(track.Id)
	if err != nil {
		return entities.NewInternalError(err)
	}

	if quality == AudioTranscodeHigh {
		if track.TranscodingHighSignature == track.FileSignature {
			if hasFile := u.transcodeStorage.DoTrackHasTranscodedQuality(track.Id, "high.ogg"); hasFile {
				return nil
			}
		}

		if err := u.transcodeProcessor.TranscodeHigh(ctx, track.Path, path.Join(transcodingDirectory, "high.ogg")); err != nil &&
			!errors.Is(err, processor.TranscoderKilledError) {
			return entities.NewInternalError(err)
		}

		track.TranscodingHighSignature = track.FileSignature
	} else if quality == AudioTranscodeMedium {
		if track.TranscodingMediumSignature == track.FileSignature {
			if hasFile := u.transcodeStorage.DoTrackHasTranscodedQuality(track.Id, "medium.ogg"); hasFile {
				return nil
			}
		}

		if err := u.transcodeProcessor.TranscodeMedium(ctx, track.Path, path.Join(transcodingDirectory, "medium.ogg")); err != nil &&
			!errors.Is(err, processor.TranscoderKilledError) {
			return entities.NewInternalError(err)
		}

		track.TranscodingMediumSignature = track.FileSignature
	} else if quality == AudioTranscodeLow {
		if track.TranscodingLowSignature == track.FileSignature {
			if hasFile := u.transcodeStorage.DoTrackHasTranscodedQuality(track.Id, "low.ogg"); hasFile {
				return nil
			}
		}

		if err := u.transcodeProcessor.TranscodeLow(ctx, track.Path, path.Join(transcodingDirectory, "low.ogg")); err != nil &&
			!errors.Is(err, processor.TranscoderKilledError) {
			return entities.NewInternalError(err)
		}

		track.TranscodingLowSignature = track.FileSignature
	}

	err = u.trackRepository.UpdateTrack(track)
	if err != nil {
		logger.MainLogger.Error("Failed to update track transcoding signatures in database")
	}

	return nil
}
