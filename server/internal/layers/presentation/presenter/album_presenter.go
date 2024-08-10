package presenter

import (
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	view_models "github.com/gungun974/Melodink/server/internal/layers/presentation/models"
	"github.com/gungun974/Melodink/server/internal/models"
)

func NewAlbumPresenter() AlbumPresenter {
	return AlbumPresenter{}
}

type AlbumPresenter struct{}

func (p *AlbumPresenter) ShowAlbums(
	albums []entities.Album,
) models.APIResponse {
	return models.JsonAPIResponse{
		Data: view_models.ConvertToAlbumsViewModel(albums),
	}
}

func (p *AlbumPresenter) ShowAlbum(
	album entities.Album,
) models.APIResponse {
	return models.JsonAPIResponse{
		Data: view_models.ConvertToAlbumViewModel(album),
	}
}
