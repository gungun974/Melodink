package controllers

import (
	"github.com/gungun974/validator"
	"gungun974.com/melodink-server/internal/layers/domain/entities"
	playlist_usecase "gungun974.com/melodink-server/internal/layers/domain/usecases/playlist"
	"gungun974.com/melodink-server/internal/models"
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

func (c *PlaylistController) ListAllAlbums() (models.APIResponse, error) {
	return c.playlistUsecase.ListAllAlbums()
}

func (c *PlaylistController) GetAlbum(rawId string) (models.APIResponse, error) {
	id, err := validator.ValidateString(
		rawId,
		validator.StringValidators{
			validator.StringMinValidator{Min: 1},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.playlistUsecase.GetAlbumById(id)
}

func (c *PlaylistController) GetAlbumCover(rawId string) (models.APIResponse, error) {
	id, err := validator.ValidateString(
		rawId,
		validator.StringValidators{
			validator.StringMinValidator{Min: 1},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.playlistUsecase.GetAlbumCover(id)
}
