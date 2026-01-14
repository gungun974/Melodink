package playlist_usecase

import (
	"context"
	"errors"

	"github.com/gabriel-vasile/mimetype"
	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *PlaylistUsecase) GetCompressedPlaylistCover(
	ctx context.Context,
	playlistId int,
	quality string,
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

	image, err := u.coverStorage.GetCompressedPlaylistCover(playlist, quality)

	if err == nil {
		mtype := mimetype.Detect(image.Bytes())

		return &models.ImageAPIResponse{
			MIMEType: mtype.String(),
			Data:     image,
		}, nil
	}

	if len(playlist.Tracks) <= 0 {
		return nil, entities.NewNotFoundError(
			"No image available for this playlist",
		)
	}

	for _, track := range playlist.Tracks {
		image, err := u.coverStorage.GetCompressedTrackCover(&track, quality)

		if err == nil {
			mtype := mimetype.Detect(image.Bytes())

			return &models.ImageAPIResponse{
				MIMEType: mtype.String(),
				Data:     image,
			}, nil
		}
	}

	return nil, entities.NewNotFoundError(
		"No image available for this playlist",
	)
}
