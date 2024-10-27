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

func (u *ArtistUsecase) GetCompressedArtistCover(
	ctx context.Context,
	artistId string,
	quality string,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	artist, err := u.artistRepository.GetArtistByIdFromUser(user.Id, artistId)
	if err != nil {
		if errors.Is(err, repository.ArtistNotFoundError) {
			return nil, entities.NewNotFoundError("Artist not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if len(artist.AllTracks) <= 0 && len(artist.AllAppearTracks) <= 0 &&
		len(artist.AllHasRoleTracks) <= 0 {
		return nil, entities.NewNotFoundError(
			"No image available for this artist",
		)
	}

	for _, track := range artist.AllTracks {
		image, err := u.coverStorage.GetCompressedTrackCover(&track, quality)

		if err == nil {
			mtype := mimetype.Detect(image.Bytes())

			return &models.ImageAPIResponse{
				MIMEType: mtype.String(),
				Data:     image,
			}, nil
		}
	}

	for _, track := range artist.AllAppearTracks {
		image, err := u.coverStorage.GetCompressedTrackCover(&track, quality)

		if err == nil {
			mtype := mimetype.Detect(image.Bytes())

			return &models.ImageAPIResponse{
				MIMEType: mtype.String(),
				Data:     image,
			}, nil
		}
	}

	for _, track := range artist.AllHasRoleTracks {
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
		"No image available for this artist",
	)
}
