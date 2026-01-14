package artist_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

type EditArtistParams struct {
	Id int

	Name string
}

func (u *ArtistUsecase) EditArtist(
	ctx context.Context,
	params EditArtistParams,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	artist, err := u.artistRepository.GetArtistById(params.Id)
	if err != nil {
		if errors.Is(err, repositories.ArtistNotFoundError) {
			return nil, entities.NewNotFoundError("Artist not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if artist.UserId != nil && *artist.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	artist.Name = params.Name

	if err := u.artistRepository.UpdateArtist(artist); err != nil {
		logger.MainLogger.Error("Couldn't update artist in Database", err, *artist)
		return nil, entities.NewInternalError(errors.New("Failed to update artist"))
	}

	return u.artistPresenter.ShowArtist(ctx, *artist), nil
}
