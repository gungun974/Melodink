package controller

import (
	"context"
	"net/http"

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

func (c *AlbumController) ListUserAlbumsWithTracks(
	ctx context.Context,
) (models.APIResponse, error) {
	return c.albumUsecase.ListUserAlbumsWithTracks(ctx)
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

func (c *AlbumController) GetCompressedUserAlbumCover(
	ctx context.Context,
	rawId string,
	quality string,
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

	return c.albumUsecase.GetCompressedAlbumCover(ctx, id, quality)
}

func (c *AlbumController) ChangeAlbumCover(
	ctx context.Context,
	r *http.Request,
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

	file, handler, err := r.FormFile("image")
	if err == nil {
		defer file.Close()

		if err := checkIfFileIsImageFile(file, handler); err != nil {
			return nil, err
		}
	} else {
		return nil, entities.NewValidationError("File can't be open")
	}

	return c.albumUsecase.ChangeAlbumCover(ctx,
		id,
		file,
	)
}

func (c *AlbumController) GetAlbumCoverSignature(
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

	return c.albumUsecase.GetAlbumCoverSignature(ctx, id)
}

func (c *AlbumController) GetAlbumCustomCoverSignature(
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

	return c.albumUsecase.GetAlbumCustomCoverSignature(ctx, id)
}

func (c *AlbumController) GetAllAlbumsCoverSignatures(
	ctx context.Context,
) (models.APIResponse, error) {
	return c.albumUsecase.GetAllAlbumsCoverSignatures(ctx)
}

func (c *AlbumController) DeleteAlbumCover(
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

	return c.albumUsecase.DeleteAlbumCover(ctx,
		id,
	)
}
