package presenter

import (
	"context"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	view_models "github.com/gungun974/Melodink/server/internal/layers/presentation/models"
	"github.com/gungun974/Melodink/server/internal/models"
)

func NewAlbumPresenter() AlbumPresenter {
	return AlbumPresenter{}
}

type AlbumPresenter struct{}

func (p *AlbumPresenter) ShowAlbums(
	ctx context.Context,
	albums []entities.Album,
) models.APIResponse {
	return models.JsonAPIResponse{
		Data: view_models.ConvertToAlbumsViewModel(ctx, albums, false),
	}
}

func (p *AlbumPresenter) ShowAlbumsWithTracks(
	ctx context.Context,
	albums []entities.Album,
) models.APIResponse {
	return models.JsonAPIResponse{
		Data: view_models.ConvertToAlbumsViewModel(ctx, albums, true),
	}
}

func (p *AlbumPresenter) ShowAlbum(
	ctx context.Context,
	album entities.Album,
) models.APIResponse {
	return models.JsonAPIResponse{
		Data: view_models.ConvertToAlbumViewModel(ctx, album),
	}
}
