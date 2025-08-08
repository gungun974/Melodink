package album_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

type CreateAlbumParams struct {
	Name string
}

func (u *AlbumUsecase) CreateAlbum(
	ctx context.Context,
	params CreateAlbumParams,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	newAlbum := entities.Album{
		UserId: &user.Id,

		Name: params.Name,
	}

	if err := u.albumRepository.CreateAlbum(&newAlbum); err != nil {
		logger.MainLogger.Error("Couldn't create album", err, newAlbum)
		return nil, entities.NewInternalError(errors.New("Failed to create album"))
	}

	return u.albumPresenter.ShowAlbum(ctx, newAlbum), nil
}
