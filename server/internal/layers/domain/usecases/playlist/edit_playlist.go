package playlist_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

type EditPlaylistParams struct {
	Id int

	Name        string
	Description string
}

func (u *PlaylistUsecase) EditPlaylist(
	ctx context.Context,
	params EditPlaylistParams,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	playlist, err := u.playlistRepository.GetPlaylist(params.Id)
	if err != nil {
		if errors.Is(err, repository.PlaylistNotFoundError) {
			return nil, entities.NewNotFoundError("Playlist not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if playlist.UserId != nil && *playlist.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	err = u.trackRepository.LoadAllScoresWithTracks(playlist.Tracks)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	playlist.Name = params.Name
	playlist.Description = params.Description

	if err := u.playlistRepository.UpdatePlaylist(playlist); err != nil {
		logger.MainLogger.Error("Couldn't update playlist in Database", err, *playlist)
		return nil, entities.NewInternalError(errors.New("Failed to update playlist"))
	}

	u.coverStorage.LoadPlaylistCoverSignature(playlist)

	return u.playlistPresenter.ShowPlaylist(ctx, *playlist), nil
}
