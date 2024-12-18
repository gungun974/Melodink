package album_usecase

import (
	"context"
	"errors"

	"github.com/gabriel-vasile/mimetype"
	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *AlbumUsecase) GetCompressedAlbumCover(
	ctx context.Context,
	albumId string,
	quality string,
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

	image, err := u.coverStorage.GetCompressedAlbumCover(&album, quality)

	if err == nil {
		mtype := mimetype.Detect(image.Bytes())

		return &models.ImageAPIResponse{
			MIMEType: mtype.String(),
			Data:     image,
		}, nil
	}

	if len(album.Tracks) <= 0 {
		return nil, entities.NewNotFoundError(
			"No image available for this album",
		)
	}

	for _, track := range album.Tracks {
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
		"No image available for this album",
	)
}
