package album_usecase

import (
	"context"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *AlbumUsecase) ListUserAlbumsWithTracks(
	ctx context.Context,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	albums, err := u.albumRepository.GetAllAlbumsFromUser(user.Id)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	return u.albumPresenter.ShowAlbumsWithTracks(ctx, albums), nil
}
