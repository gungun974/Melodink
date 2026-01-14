package album_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *AlbumUsecase) GetUserAlbumById(
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

	err = u.trackRepository.LoadAllScoresWithTracks(album.Tracks)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	err = u.trackRepository.LoadAlbumsInTracks(album.Tracks)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	err = u.trackRepository.LoadArtistsInTracks(album.Tracks)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	return u.albumPresenter.ShowAlbum(ctx, *album), nil
}
