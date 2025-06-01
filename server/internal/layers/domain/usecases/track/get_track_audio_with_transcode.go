package track_usecase

import (
	"context"
	"errors"
	"path"

	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *TrackUsecase) GetTrackAudioWithTranscode(
	ctx context.Context,
	trackId int,
	quality AudioTranscodeQuality,
	fileSignature *string,
) (models.APIResponse, error) {
	track, err := u.trackRepository.GetTrack(trackId)
	if err != nil {
		if errors.Is(err, repository.TrackNotFoundError) {
			return nil, entities.NewNotFoundError("Track not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if fileSignature != nil && *fileSignature != track.FileSignature {
		return nil, entities.NewNotFoundError("Track file have changed")
	}

	err = u.TranscodeTrack(ctx, trackId, quality)
	if err != nil {
		return nil, err
	}

	transcodingDirectory, err := u.transcodeStorage.GetTrackTranscodeDirectory(track.Id)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	if quality == AudioTranscodeHigh {
		return models.FileAPIResponse{
			MIMEType: "audio/ogg",
			Path:     path.Join(transcodingDirectory, "high.ogg"),
		}, nil
	}
	if quality == AudioTranscodeMedium {
		return models.FileAPIResponse{
			MIMEType: "audio/ogg",
			Path:     path.Join(transcodingDirectory, "medium.ogg"),
		}, nil
	}

	return models.FileAPIResponse{
		MIMEType: "audio/ogg",
		Path:     path.Join(transcodingDirectory, "low.ogg"),
	}, nil
}
