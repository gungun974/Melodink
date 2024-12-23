package playlist_usecase

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

func (u *PlaylistUsecase) ChangePlaylistCover(
	ctx context.Context,
	playlistId int,
	file io.Reader,
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

	err = u.coverStorage.UploadCustomPlaylistCover(playlist, file)
	if err != nil {
		logger.MainLogger.Error("Failed to save uploaded Cover")
		return nil, err
	}

	return u.playlistPresenter.ShowPlaylist(ctx, *playlist), nil
}
