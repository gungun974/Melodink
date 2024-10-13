package album_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
	"github.com/gungun974/Melodink/server/pkgs/audioimage"
)

func (u *AlbumUsecase) GetAlbumCover(
	ctx context.Context,
	albumId string,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	album, err := u.albumRepository.GetAlbumByIdFromUser(user.Id, albumId)
	if err != nil {
		if errors.Is(err, repository.AlbumNotFoundError) {
			return nil, entities.NewNotFoundError("Album not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if len(album.Tracks) <= 0 {
		return nil, entities.NewNotFoundError(
			"No image available for this album",
		)
	}

	for _, track := range album.Tracks {
		image, err := audioimage.GetAudioImage(track.Path)
		if err == nil {
			return &models.ImageAPIResponse{
				MIMEType: image.MIMEType,
				Data:     image.Data,
			}, nil
		}
	}

	return nil, entities.NewNotFoundError(
		"No image available for this album",
	)
}
