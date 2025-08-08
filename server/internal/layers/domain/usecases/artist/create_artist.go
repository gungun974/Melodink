package artist_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

type CreateArtistParams struct {
	Name string
}

func (u *ArtistUsecase) CreateArtist(
	ctx context.Context,
	params CreateArtistParams,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	newArtist := entities.Artist{
		UserId: &user.Id,

		Name: params.Name,
	}

	if err := u.artistRepository.CreateArtist(&newArtist); err != nil {
		logger.MainLogger.Error("Couldn't create artist", err, newArtist)
		return nil, entities.NewInternalError(errors.New("Failed to create artist"))
	}

	return u.artistPresenter.ShowArtist(ctx, newArtist), nil
}
