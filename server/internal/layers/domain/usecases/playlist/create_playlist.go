package playlist_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

type CreatePlaylistParams struct {
	Name        string
	Description string
}

func (u *PlaylistUsecase) CreatePlaylist(
	ctx context.Context,
	params CreatePlaylistParams,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	newPlaylist := entities.Playlist{
		UserId: &user.Id,

		Name:        params.Name,
		Description: params.Description,
	}

	if err := u.playlistRepository.CreatePlaylist(&newPlaylist); err != nil {
		logger.MainLogger.Error("Couldn't create playlist", err, newPlaylist)
		return nil, entities.NewInternalError(errors.New("Failed to create playlist"))
	}

	return u.playlistPresenter.ShowPlaylist(newPlaylist), nil
}
