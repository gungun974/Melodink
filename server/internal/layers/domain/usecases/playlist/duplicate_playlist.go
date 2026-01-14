package playlist_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/data/storages"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *PlaylistUsecase) DuplicatePlaylist(
	ctx context.Context,
	playlistId int,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	originalPlaylist, err := u.playlistRepository.GetPlaylist(playlistId)
	if err != nil {
		if errors.Is(err, repositories.PlaylistNotFoundError) {
			return nil, entities.NewNotFoundError("Playlist not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if originalPlaylist.UserId != nil && *originalPlaylist.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	err = u.trackRepository.LoadAllScoresWithTracks(originalPlaylist.Tracks)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	newPlaylist := *originalPlaylist

	newPlaylist.UserId = &user.Id
	newPlaylist.Name = originalPlaylist.Name + " (2)"

	if err := u.playlistRepository.CreatePlaylist(&newPlaylist); err != nil {
		logger.MainLogger.Error("Couldn't create playlist", err, newPlaylist)
		return nil, entities.NewInternalError(errors.New("Failed to create playlist"))
	}

	newPlaylist.Tracks = originalPlaylist.Tracks

	if err := u.playlistRepository.SetPlaylistTracks(&newPlaylist); err != nil {
		logger.MainLogger.Error("Couldn't update playlist tracks in Database", err, newPlaylist)
		return nil, entities.NewInternalError(errors.New("Failed to update playlist tracks"))
	}

	err = u.coverStorage.DuplicatePlaylistCover(originalPlaylist, &newPlaylist)
	if err != nil && !errors.Is(err, storages.OriginalCoverNotFoundError) {
		logger.MainLogger.Error("Failed to duplicate playlist Cover")
		return nil, err
	}

	u.coverStorage.LoadPlaylistCoverSignature(&newPlaylist)

	return u.playlistPresenter.ShowPlaylist(ctx, newPlaylist), nil
}
