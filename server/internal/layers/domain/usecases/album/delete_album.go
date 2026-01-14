package album_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *AlbumUsecase) DeleteAlbum(
	ctx context.Context,
	albumId int,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	album, err := u.albumRepository.GetAlbumById(albumId)
	if err != nil {
		if errors.Is(err, repositories.AlbumNotFoundError) {
			return nil, entities.NewNotFoundError("Album not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if album.UserId != nil && *album.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	if err := u.coverStorage.RemoveAlbumCoverFiles(album); err != nil {
		logger.MainLogger.Warn("Couldn't delete cover files from storage", err, *album)
	}

	if err := u.albumRepository.DeleteAlbum(album); err != nil {
		logger.MainLogger.Error("Couldn't delete album from Database", err, *album)
		return nil, entities.NewInternalError(errors.New("Failed to delete album"))
	}

	return u.albumPresenter.ShowAlbum(ctx, *album), nil
}
