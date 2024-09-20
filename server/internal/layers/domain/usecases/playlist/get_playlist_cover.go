package playlist_usecase

import (
	"bytes"
	"context"
	"errors"
	"os"

	"github.com/dhowden/tag"
	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
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
		file, err := os.Open(track.Path)
		if err != nil {
			return nil, entities.NewInternalError(err)
		}

		defer file.Close()

		metadata, err := tag.ReadFrom(file)
		if err != nil {
			return nil, entities.NewInternalError(err)
		}

		picture := metadata.Picture()

		if picture != nil {
			return &models.ImageAPIResponse{
				MIMEType: picture.MIMEType,
				Data:     *bytes.NewBuffer(picture.Data),
			}, nil
		}

	}

	return nil, entities.NewNotFoundError(
		"No image available for this playlist",
	)
}
