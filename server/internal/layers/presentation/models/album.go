package view_models

import (
	"context"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type AlbumViewModel struct {
	Id int `json:"id"`

	UserId *int `json:"user_id"`

	Name string `json:"name"`

	Artists []int `json:"artists"`

	CoverSignature string `json:"cover_signature"`
}

func ConvertToAlbumsViewModel(
	ctx context.Context,
	albums []entities.Album,
) []AlbumViewModel {
	albumsViewModels := make([]AlbumViewModel, len(albums))

	for i, album := range albums {
		albumsViewModels[i] = ConvertToAlbumViewModel(ctx, album)
	}

	return albumsViewModels
}

func ConvertToAlbumViewModel(
	ctx context.Context,
	album entities.Album,
) AlbumViewModel {
	artists := make([]int, len(album.Artists))

	for i, artist := range album.Artists {
		artists[i] = artist.Id
	}

	return AlbumViewModel{
		Id: album.Id,

		UserId: album.UserId,

		Name: album.Name,

		Artists: artists,

		CoverSignature: album.CoverSignature,
	}
}
