package track_usecase

import (
	"bytes"
	"context"
	"errors"
	"os"

	"github.com/dhowden/tag"
	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
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

	file, err := os.Open(track.Path)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}
	defer file.Close()

	metadata, err := tag.ReadFrom(file)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	picture := metadata.Picture()

	if picture == nil {
		return nil, entities.NewNotFoundError(
			"No image available for this track",
		)
	}

	return &models.ImageAPIResponse{
		MIMEType: picture.MIMEType,
		Data:     *bytes.NewBuffer(picture.Data),
	}, nil
}
