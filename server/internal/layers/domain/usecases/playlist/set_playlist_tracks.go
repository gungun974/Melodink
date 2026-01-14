package playlist_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

type SetPlaylistTracksParams struct {
	Id int

	TrackIds []int
}

func (u *PlaylistUsecase) SetPlaylistTracks(
	ctx context.Context,
	params SetPlaylistTracksParams,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	playlist, err := u.playlistRepository.GetPlaylist(params.Id)
	if err != nil {
		if errors.Is(err, repositories.PlaylistNotFoundError) {
			return nil, entities.NewNotFoundError("Playlist not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if playlist.UserId != nil && *playlist.UserId != user.Id {
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

	playlist.Tracks = tracks

	if err := u.playlistRepository.SetPlaylistTracks(playlist); err != nil {
		logger.MainLogger.Error("Couldn't update playlist tracks in Database", err, *playlist)
		return nil, entities.NewInternalError(errors.New("Failed to update playlist tracks"))
	}

	err = u.trackRepository.LoadAllScoresWithTracks(playlist.Tracks)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	u.coverStorage.LoadPlaylistCoverSignature(playlist)

	return u.playlistPresenter.ShowPlaylist(ctx, *playlist), nil
}
