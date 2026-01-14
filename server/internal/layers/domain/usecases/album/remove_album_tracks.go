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

type RemoveAlbumTracksParams struct {
	Id       int
	TrackIds []int
}

func (u *AlbumUsecase) RemoveAlbumTracksParams(
	ctx context.Context,
	params RemoveAlbumTracksParams,
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

	tracks := make([]entities.Track, len(params.TrackIds))

	for i, trackId := range params.TrackIds {
		track, err := u.trackRepository.GetTrack(trackId)
		if err != nil {
			if errors.Is(err, repositories.TrackNotFoundError) {
				return nil, entities.NewNotFoundError("Track not found")
			}
			return nil, entities.NewInternalError(err)
		}

		if track.UserId != nil && *track.UserId != user.Id {
			return nil, entities.NewUnauthorizedError()
		}

		tracks[i] = *track
	}

	album.Tracks = tracks

	if err := u.albumRepository.RemoveAlbumTracks(album); err != nil {
		logger.MainLogger.Error("Couldn't remove album tracks", err, album)
		return nil, entities.NewInternalError(errors.New("Failed to remove album tracks"))
	}

	return u.albumPresenter.ShowAlbum(ctx, *album), nil
}
