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

func (c *AlbumController) GetUserAlbum(
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

	return c.albumUsecase.GetUserAlbumById(ctx, id)
}

func (c *AlbumController) GetUserAlbumCover(
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

	return c.albumUsecase.GetAlbumCover(ctx, id)
}

func (c *AlbumController) GetCompressedUserAlbumCover(
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

	return c.albumUsecase.GetCompressedAlbumCover(ctx, id, quality)
}

func (c *AlbumController) ChangeAlbumCover(
	ctx context.Context,
	r *http.Request,
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

	file, handler, err := r.FormFile("image")
	if err == nil {
		defer file.Close()

		if err := checkIfFileIsImageFile(file, handler); err != nil {
			_ = r.MultipartForm.RemoveAll()
			return nil, err
		}
	} else {
		return nil, entities.NewValidationError("File can't be open")
	}

	defer func() {
		_ = r.MultipartForm.RemoveAll()
	}()

	return c.albumUsecase.ChangeAlbumCover(ctx,
		id,
		file,
	)
}

func (c *AlbumController) GetAlbumCoverSignature(
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

	return c.albumUsecase.GetAlbumCoverSignature(ctx, id)
}

func (c *AlbumController) GetAlbumCustomCoverSignature(
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
	id, err := validator.CoerceAndValidateInt(
		rawId,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.albumUsecase.DeleteAlbumCover(ctx,
		id,
	)
}

func (c *AlbumController) CreateAlbum(
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

	return c.albumUsecase.CreateAlbum(ctx, album_usecase.CreateAlbumParams{
		Name: name,
	})
}

func (c *AlbumController) EditAlbum(
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

	return c.albumUsecase.EditAlbum(ctx, album_usecase.EditAlbumParams{
		Id: id,

		Name: name,
	})
}

func (c *AlbumController) AddAlbumTracks(
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

	rawTrackIds, ok := bodyData["track_ids"]
	if !ok {
		return nil, entities.NewValidationError("missing key \"track_ids\"")
	}

	unknownTrackIds, ok := rawTrackIds.([]any)
	if !ok {
		return nil, entities.NewValidationError("\"track_ids\" should be an array")
	}

	trackIds := make([]int, len(unknownTrackIds))

	for i, trackId := range unknownTrackIds {
		id, err := validator.CoerceAndValidateInt(
			trackId,
			validator.IntValidators{
				validator.IntMinValidator{Min: 0},
			},
		)
		if err != nil {
			return nil, entities.NewValidationError(err.Error())
		}
		trackIds[i] = id
	}

	return c.albumUsecase.AddAlbumTracks(ctx, album_usecase.AddAlbumTracksParams{
		Id:       id,
		TrackIds: trackIds,
	})
}

func (c *AlbumController) RemoveAlbumTracks(
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

	rawTrackIds, ok := bodyData["track_ids"]
	if !ok {
		return nil, entities.NewValidationError("missing key \"track_ids\"")
	}

	unknownTrackIds, ok := rawTrackIds.([]any)
	if !ok {
		return nil, entities.NewValidationError("\"track_ids\" should be an array")
	}

	trackIds := make([]int, len(unknownTrackIds))

	for i, trackId := range unknownTrackIds {
		id, err := validator.CoerceAndValidateInt(
			trackId,
			validator.IntValidators{
				validator.IntMinValidator{Min: 0},
			},
		)
		if err != nil {
			return nil, entities.NewValidationError(err.Error())
		}
		trackIds[i] = id
	}

	return c.albumUsecase.RemoveAlbumTracksParams(ctx, album_usecase.RemoveAlbumTracksParams{
		Id:       id,
		TrackIds: trackIds,
	})
}

func (c *AlbumController) SetAlbumArtists(
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

	rawArtistIds, ok := bodyData["artist_ids"]
	if !ok {
		return nil, entities.NewValidationError("missing key \"artist_ids\"")
	}

	unknownArtistIds, ok := rawArtistIds.([]any)
	if !ok {
		return nil, entities.NewValidationError("\"artist_ids\" should be an array")
	}

	artistIds := make([]int, len(unknownArtistIds))

	for i, artistId := range unknownArtistIds {
		id, err := validator.CoerceAndValidateInt(
			artistId,
			validator.IntValidators{
				validator.IntMinValidator{Min: 0},
			},
		)
		if err != nil {
			return nil, entities.NewValidationError(err.Error())
		}
		artistIds[i] = id
	}

	return c.albumUsecase.SetAlbumArtists(ctx, album_usecase.SetAlbumArtistsParams{
		Id:        id,
		ArtistIds: artistIds,
	})
}

func (c *AlbumController) DeleteAlbum(
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

	return c.albumUsecase.DeleteAlbum(ctx, id)
}
