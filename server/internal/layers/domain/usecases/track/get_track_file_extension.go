package track_usecase

import (
	"context"
	"errors"

	"github.com/gabriel-vasile/mimetype"
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *TrackUsecase) GetTrackFileExtension(
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

	mtype, err := mimetype.DetectFile(track.Path)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	return models.PlainAPIResponse{
		Text: mtype.Extension(),
	}, nil
}
