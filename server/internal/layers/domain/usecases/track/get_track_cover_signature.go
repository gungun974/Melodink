package track_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *TrackUsecase) GetTrackCoverSignature(
	ctx context.Context,
	trackId int,
) (models.APIResponse, error) {
	track, err := u.trackRepository.GetTrack(trackId)
	if err != nil {
		if errors.Is(err, repositories.TrackNotFoundError) {
			return nil, entities.NewNotFoundError("Track not found")
		}
		return nil, entities.NewInternalError(err)
	}

	return models.PlainAPIResponse{
		Text: track.CoverSignature,
	}, nil
}
