package controller

import (
	"context"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	playlist_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/playlist"
	"github.com/gungun974/Melodink/server/internal/models"
	"github.com/gungun974/validator"
)

type PlaylistController struct {
	playlistUsecase playlist_usecase.PlaylistUsecase
}

func NewPlaylistController(
	playlistUsecase playlist_usecase.PlaylistUsecase,
) PlaylistController {
	return PlaylistController{
		playlistUsecase,
	}
}

func (c *PlaylistController) ListUserPlaylists(
	ctx context.Context,
) (models.APIResponse, error) {
	return c.playlistUsecase.ListUserPlaylists(ctx)
}

func (c *PlaylistController) GetPlaylist(
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

	return c.playlistUsecase.GetPlaylistById(ctx, id)
}

func (c *PlaylistController) CreatePlaylist(
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

	description, err := validator.ValidateMapString(
		"description",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.playlistUsecase.CreatePlaylist(ctx, playlist_usecase.CreatePlaylistParams{
		Name:        name,
		Description: description,
	})
}

func (c *PlaylistController) EditPlaylist(
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

	description, err := validator.ValidateMapString(
		"description",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.playlistUsecase.EditPlaylist(ctx, playlist_usecase.EditPlaylistParams{
		Id: id,

		Name:        name,
		Description: description,
	})
}

func (c *PlaylistController) DuplicatePlaylist(
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

	return c.playlistUsecase.DuplicatePlaylist(ctx, id)
}

func (c *PlaylistController) DeletePlaylist(
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

	return c.playlistUsecase.DeletePlaylist(ctx, id)
}

func (c *PlaylistController) SetPlaylistTracks(
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

	unkownTrackIds, ok := rawTrackIds.([]any)
	if !ok {
		return nil, entities.NewValidationError("\"track_ids\" should be an array")
	}

	trackIds := make([]int, len(unkownTrackIds))

	for i, trackId := range unkownTrackIds {
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

	return c.playlistUsecase.SetPlaylistTracks(ctx, playlist_usecase.SetPlaylistTracksParams{
		Id: id,

		TrackIds: trackIds,
	})
}

func (c *PlaylistController) GetPlaylistCover(
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

	return c.playlistUsecase.GetPlaylistCover(ctx, id)
}
