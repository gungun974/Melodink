package artist_usecase

import (
	"context"
	"errors"

	"github.com/gabriel-vasile/mimetype"
	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *ArtistUsecase) GetArtistCover(
	ctx context.Context,
	artistId int,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	artist, err := u.artistRepository.GetArtistById(artistId)
	if err != nil {
		if errors.Is(err, repository.ArtistNotFoundError) {
			return nil, entities.NewNotFoundError("Artist not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if artist.UserId != nil && *artist.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	if len(artist.AllTracks) <= 0 && len(artist.AllAppearTracks) <= 0 &&
		len(artist.AllHasRoleTracks) <= 0 {
		return nil, entities.NewNotFoundError(
			"No image available for this artist",
		)
	}

	for _, track := range artist.AllTracks {
		image, err := u.coverStorage.GetOriginalTrackCover(&track)

		if err == nil {
			mtype := mimetype.Detect(image.Bytes())

			return &models.ImageAPIResponse{
				MIMEType: mtype.String(),
				Data:     image,
			}, nil
		}
	}

	for _, track := range artist.AllAppearTracks {
		image, err := u.coverStorage.GetOriginalTrackCover(&track)

		if err == nil {
			mtype := mimetype.Detect(image.Bytes())

			return &models.ImageAPIResponse{
				MIMEType: mtype.String(),
				Data:     image,
			}, nil
		}
	}

	for _, track := range artist.AllHasRoleTracks {
		image, err := u.coverStorage.GetOriginalTrackCover(&track)

		if err == nil {
			mtype := mimetype.Detect(image.Bytes())

			return &models.ImageAPIResponse{
				MIMEType: mtype.String(),
				Data:     image,
			}, nil
		}
	}

	return nil, entities.NewNotFoundError(
		"No image available for this artist",
	)
}
