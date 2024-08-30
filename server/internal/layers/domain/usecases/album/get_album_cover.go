package album_usecase

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
		"No image available for this album",
	)
}
