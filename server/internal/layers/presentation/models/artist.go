package view_models

import (
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type ArtistViewModel struct {
	Id string `json:"id"`

	UserId *int `json:"user_id"`

	Name string `json:"name"`

	Albums []AlbumViewModel `json:"albums"`

	AllTracks []MinimalTrackViewModel `json:"all_tracks"`
}

func ConvertToArtistsViewModel(
	artists []entities.Artist,
) []ArtistViewModel {
	artistsViewModels := make([]ArtistViewModel, len(artists))

	for i, artist := range artists {
		artist.Albums = nil
		artist.AllTracks = nil

		artistsViewModels[i] = ConvertToArtistViewModel(artist)
	}

	return artistsViewModels
}

func ConvertToArtistViewModel(
	artist entities.Artist,
) ArtistViewModel {
	allTracksViewModels := make([]MinimalTrackViewModel, len(artist.AllTracks))

	for i, track := range artist.AllTracks {
		allTracksViewModels[i] = ConvertToMinimalTrackViewModel(track)
	}

	albumsViewModels := make([]AlbumViewModel, len(artist.Albums))

	for i, album := range artist.Albums {
		album.Tracks = nil

		albumsViewModels[i] = ConvertToAlbumViewModel(album)
	}

	return ArtistViewModel{
		Id: artist.Id,

		UserId: artist.UserId,

		Name: artist.Name,

		Albums: albumsViewModels,

		AllTracks: allTracksViewModels,
	}
}
