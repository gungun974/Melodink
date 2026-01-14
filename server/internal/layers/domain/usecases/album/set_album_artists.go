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

type SetAlbumArtistsParams struct {
	Id        int
	ArtistIds []int
}

func (u *AlbumUsecase) SetAlbumArtists(
	ctx context.Context,
	params SetAlbumArtistsParams,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	album, err := u.albumRepository.GetAlbumById(params.Id)
	if err != nil {
		if errors.Is(err, repositories.AlbumNotFoundError) {
			return nil, entities.NewNotFoundError("Album not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if album.UserId != nil && *album.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	artists := make([]entities.Artist, len(params.ArtistIds))

	for i, trackId := range params.ArtistIds {
		artist, err := u.artistRepository.GetArtistById(trackId)
		if err != nil {
			if errors.Is(err, repositories.ArtistNotFoundError) {
				return nil, entities.NewNotFoundError("Artist not found")
			}
			return nil, entities.NewInternalError(err)
		}

		if artist.UserId != nil && *artist.UserId != user.Id {
			return nil, entities.NewUnauthorizedError()
		}

		artists[i] = *artist
	}

	album.Artists = artists

	if err := u.albumRepository.SetAlbumArtists(album); err != nil {
		logger.MainLogger.Error("Couldn't set album artists", err, album)
		return nil, entities.NewInternalError(errors.New("Failed to set album artists"))
	}

	return u.albumPresenter.ShowAlbum(ctx, *album), nil
}
