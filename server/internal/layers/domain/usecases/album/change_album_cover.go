package album_usecase

import (
	"context"
	"errors"
	"io"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *AlbumUsecase) ChangeAlbumCover(
	ctx context.Context,
	albumId string,
	file io.Reader,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	album, err := u.albumRepository.GetAlbumByIdFromUser(user.Id, albumId)
	if err != nil {
		if errors.Is(err, repository.AlbumNotFoundError) {
			return nil, entities.NewNotFoundError("Album not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if album.UserId != nil && *album.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	err = u.coverStorage.UploadCustomAlbumCover(&album, file)
	if err != nil {
		logger.MainLogger.Error("Failed to save uploaded Cover")
		return nil, err
	}

	return u.albumPresenter.ShowAlbum(album), nil
}
