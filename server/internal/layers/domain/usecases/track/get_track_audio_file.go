package track_usecase

import (
	"context"
	"errors"

	"github.com/gabriel-vasile/mimetype"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *TrackUsecase) GetTrackAudioFile(
	ctx context.Context,
	trackId int,
) (models.APIResponse, error) {
	track, err := u.trackRepository.GetTrack(trackId)
	if err != nil {
		if errors.Is(err, repository.TrackNotFoundError) {
			return nil, entities.NewNotFoundError("Track not found")
		}
		return nil, entities.NewInternalError(err)
	}

	mtype, err := mimetype.DetectFile(track.Path)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	return models.FileAPIResponse{
		MIMEType: mtype.String(),
		Path:     track.Path,
	}, nil
}
