package track_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

type SetTrackAlbumsParams struct {
	Id       int
	AlbumIds []int
}

func (u *TrackUsecase) SetTrackAlbums(
	ctx context.Context,
	params SetTrackAlbumsParams,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	track, err := u.trackRepository.GetTrack(params.Id)
	if err != nil {
		if errors.Is(err, repository.TrackNotFoundError) {
			return nil, entities.NewNotFoundError("Track not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if track.UserId != nil && *track.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	albums := make([]entities.Album, len(params.AlbumIds))

	for i, trackId := range params.AlbumIds {
		album, err := u.albumRepository.GetAlbumById(trackId)
		if err != nil {
			if errors.Is(err, repository.AlbumNotFoundError) {
				return nil, entities.NewNotFoundError("Album not found")
			}
			return nil, entities.NewInternalError(err)
		}

		if album.UserId != nil && *album.UserId != user.Id {
			return nil, entities.NewUnauthorizedError()
		}

		albums[i] = *album
	}

	track.Albums = albums

	if err := u.trackRepository.SetTrackAlbums(track); err != nil {
		logger.MainLogger.Error("Couldn't set track albums", err, track)
		return nil, entities.NewInternalError(errors.New("Failed to set track albums"))
	}

	return u.trackPresenter.ShowTrack(ctx, *track), nil
}
