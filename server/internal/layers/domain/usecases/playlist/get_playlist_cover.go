package playlist_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
	"github.com/gungun974/Melodink/server/pkgs/audioimage"
)

func (u *PlaylistUsecase) GetPlaylistCover(
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

	if len(playlist.Tracks) <= 0 {
		return nil, entities.NewNotFoundError(
			"No image available for this playlist",
		)
	}

	for _, track := range playlist.Tracks {
		image, err := audioimage.GetAudioImage(track.Path)
		if err == nil {
			return &models.ImageAPIResponse{
				MIMEType: image.MIMEType,
				Data:     image.Data,
			}, nil
		}
	}

	return nil, entities.NewNotFoundError(
		"No image available for this playlist",
	)
}
