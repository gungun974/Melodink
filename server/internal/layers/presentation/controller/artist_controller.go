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
	id, err := validator.CoerceAndValidateInt(
		rawId,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
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
	id, err := validator.CoerceAndValidateInt(
		rawId,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.artistUsecase.GetUserArtistAlbums(ctx, id)
}

func (c *ArtistController) GetUserArtistCover(
	ctx context.Context,
	rawId string,
) (models.APIResponse, error) {
	id, err := validator.CoerceAndValidateInt(
		rawId,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.artistUsecase.GetArtistCover(ctx, id)
}

func (c *ArtistController) GetCompressedUserArtistCover(
	ctx context.Context,
	rawId string,
	quality string,
) (models.APIResponse, error) {
	id, err := validator.CoerceAndValidateInt(
		rawId,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.artistUsecase.GetCompressedArtistCover(ctx, id, quality)
}

func (c *ArtistController) CreateArtist(
	ctx context.Context,
	bodyData map[string]any,
) (models.APIResponse, error) {
	name, err := validator.ValidateMapString(
		"name",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 1},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.artistUsecase.CreateArtist(ctx, artist_usecase.CreateArtistParams{
		Name: name,
	})
}

func (c *ArtistController) EditArtist(
	ctx context.Context,
	rawId string,
	bodyData map[string]any,
) (models.APIResponse, error) {
	id, err := validator.CoerceAndValidateInt(
		rawId,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	name, err := validator.ValidateMapString(
		"name",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 1},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.artistUsecase.EditArtist(ctx, artist_usecase.EditArtistParams{
		Id: id,

		Name: name,
	})
}

func (c *ArtistController) DeleteArtist(
	ctx context.Context,
	rawId string,
) (models.APIResponse, error) {
	id, err := validator.CoerceAndValidateInt(
		rawId,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.artistUsecase.DeleteArtist(ctx, id)
}
