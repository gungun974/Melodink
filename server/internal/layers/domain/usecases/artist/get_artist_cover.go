package artist_usecase

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

func (u *ArtistUsecase) GetArtistCover(
	ctx context.Context,
	artistId string,
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

	for _, track := range artist.AllAppearTracks {
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

	for _, track := range artist.AllHasRoleTracks {
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
		"No image available for this artist",
	)
}
