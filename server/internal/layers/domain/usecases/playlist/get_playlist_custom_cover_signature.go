package playlist_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *PlaylistUsecase) GetPlaylistCustomCoverSignature(
	ctx context.Context,
	playlistId int,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	playlist, err := u.playlistRepository.GetPlaylist(playlistId)
	if err != nil {
		if errors.Is(err, repositories.PlaylistNotFoundError) {
			return nil, entities.NewNotFoundError("Playlist not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if playlist.UserId != nil && *playlist.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	return models.PlainAPIResponse{
		Text: u.coverStorage.GetPlaylistCoverSignature(playlist),
	}, nil
}
