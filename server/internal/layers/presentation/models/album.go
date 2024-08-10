package view_models

import (
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type AlbumViewModel struct {
	Id string `json:"id"`

	UserId *int `json:"user_id"`

	Name string `json:"name"`

	AlbumArtist string `json:"album_artist"`

	Tracks []MinimalTrackViewModel `json:"tracks"`
}

func ConvertToAlbumsViewModel(
	albums []entities.Album,
) []AlbumViewModel {
	albumsViewModels := make([]AlbumViewModel, len(albums))

	for i, album := range albums {
		album.Tracks = nil

		albumsViewModels[i] = ConvertToAlbumViewModel(album)
	}

	return albumsViewModels
}

func ConvertToAlbumViewModel(
	album entities.Album,
) AlbumViewModel {
	tracksViewModels := make([]MinimalTrackViewModel, len(album.Tracks))

	for i, track := range album.Tracks {
		tracksViewModels[i] = ConvertToMinimalTrackViewModel(track)
	}

	return AlbumViewModel{
		Id: album.Id,

		UserId: album.UserId,

		Name: album.Name,

		AlbumArtist: album.AlbumArtist,

		Tracks: tracksViewModels,
	}
}
