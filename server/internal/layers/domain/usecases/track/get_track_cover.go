package track_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
	"github.com/gungun974/Melodink/server/pkgs/audioimage"
)

func (u *TrackUsecase) GetTrackCover(
	ctx context.Context,
	trackId int,
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

	image, err := audioimage.GetAudioImage(track.Path)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	return &models.ImageAPIResponse{
		MIMEType: image.MIMEType,
		Data:     image.Data,
	}, nil
}
