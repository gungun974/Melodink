package artist_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *ArtistUsecase) GetUserArtistAlbums(
	ctx context.Context,
	artistId int,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	artist, err := u.artistRepository.GetArtistById(artistId)
	if err != nil {
		if errors.Is(err, repository.ArtistNotFoundError) {
			return nil, entities.NewNotFoundError("Artist not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if artist.UserId != nil && *artist.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	return u.artistPresenter.ShowAllArtistAlbums(ctx, *artist), nil
}
