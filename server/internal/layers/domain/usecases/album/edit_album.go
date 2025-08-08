package album_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

type EditAlbumParams struct {
	Id int

	Name string
}

func (u *AlbumUsecase) EditAlbum(
	ctx context.Context,
	params EditAlbumParams,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	album, err := u.albumRepository.GetAlbumById(params.Id)
	if err != nil {
		if errors.Is(err, repository.AlbumNotFoundError) {
			return nil, entities.NewNotFoundError("Album not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if album.UserId != nil && *album.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	album.Name = params.Name

	if err := u.albumRepository.UpdateAlbum(album); err != nil {
		logger.MainLogger.Error("Couldn't update album in Database", err, *album)
		return nil, entities.NewInternalError(errors.New("Failed to update album"))
	}

	return u.albumPresenter.ShowAlbum(ctx, *album), nil
}
