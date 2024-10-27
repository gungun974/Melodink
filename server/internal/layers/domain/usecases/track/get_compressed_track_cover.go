package track_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/data/storage"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *TrackUsecase) GetCompressedTrackCover(
	ctx context.Context,
	trackId int,
	quality string,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	track, err := u.trackRepository.GetTrack(trackId)
	if err != nil {
		if errors.Is(err, repository.TrackNotFoundError) {
			return nil, entities.NewNotFoundError("Track not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if track.UserId != nil && *track.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	image, err := u.coverStorage.GetCompressedTrackCover(track, quality)
	if err != nil {
		if errors.Is(err, storage.CoverQualityNotFoundError) {
			return nil, entities.NewNotFoundError("Cover quality not found")
		}
		return nil, entities.NewInternalError(err)
	}

	return &models.ImageAPIResponse{
		MIMEType: "image/webp",
		Data:     image,
	}, nil
}
