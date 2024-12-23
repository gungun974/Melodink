package artist_usecase

import (
	"context"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *ArtistUsecase) ListUserArtists(
	ctx context.Context,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	artists, err := u.artistRepository.GetAllArtistsFromUser(user.Id)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	return u.artistPresenter.ShowArtists(ctx, artists), nil
}
