package controller

import (
	"context"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	artist_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/artist"
	"github.com/gungun974/Melodink/server/internal/models"
	"github.com/gungun974/validator"
)

type ArtistController struct {
	artistUsecase artist_usecase.ArtistUsecase
}

func NewArtistController(
	artistUsecase artist_usecase.ArtistUsecase,
) ArtistController {
	return ArtistController{
		artistUsecase,
	}
}

func (c *ArtistController) ListUserArtists(
	ctx context.Context,
) (models.APIResponse, error) {
	return c.artistUsecase.ListUserArtists(ctx)
}

func (c *ArtistController) GetUserArtistTracks(
	ctx context.Context,
	rawId string,
) (models.APIResponse, error) {
	id, err := validator.ValidateString(
		rawId,
		validator.StringValidators{
			validator.StringMinValidator{Min: 1},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.artistUsecase.GetUserArtistTracks(ctx, id)
}

func (c *ArtistController) GetUserArtistAlbums(
	ctx context.Context,
	rawId string,
) (models.APIResponse, error) {
	id, err := validator.ValidateString(
		rawId,
		validator.StringValidators{
			validator.StringMinValidator{Min: 1},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.artistUsecase.GetUserArtistAlbums(ctx, id)
}
