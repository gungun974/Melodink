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

func (u *PlaylistUsecase) DeletePlaylist(
	ctx context.Context,
	playlistId int,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	playlist, err := u.playlistRepository.GetPlaylist(playlistId)
	if err != nil {
		if errors.Is(err, repository.PlaylistNotFoundError) {
			return nil, entities.NewNotFoundError("Playlist not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if playlist.UserId != nil && *playlist.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	if err := u.coverStorage.RemovePlaylistCoverFiles(playlist); err != nil {
		logger.MainLogger.Warn("Couldn't delete cover files from storage", err, *playlist)
	}

	if err := u.playlistRepository.DeletePlaylist(playlist); err != nil {
		logger.MainLogger.Error("Couldn't delete playlist from Database", err, *playlist)
		return nil, entities.NewInternalError(errors.New("Failed to delete playlist"))
	}

	return u.playlistPresenter.ShowPlaylist(*playlist), nil
}
