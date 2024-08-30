package controller

import (
	"context"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	album_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/album"
	"github.com/gungun974/Melodink/server/internal/models"
	"github.com/gungun974/validator"
)

type AlbumController struct {
	albumUsecase album_usecase.AlbumUsecase
}

func NewAlbumController(
	albumUsecase album_usecase.AlbumUsecase,
) AlbumController {
	return AlbumController{
		albumUsecase,
	}
}

func (c *AlbumController) ListUserAlbums(
	ctx context.Context,
) (models.APIResponse, error) {
	return c.albumUsecase.ListUserAlbums(ctx)
}

func (c *AlbumController) GetUserAlbum(
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

	return c.albumUsecase.GetUserAlbumById(ctx, id)
}

func (c *AlbumController) GetUserAlbumCover(
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

	return c.albumUsecase.GetAlbumCover(ctx, id)
}
