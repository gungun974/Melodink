package view_models

import (
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type ArtistViewModel struct {
	Id string `json:"id"`

	UserId *int `json:"user_id"`

	Name string `json:"name"`

	Albums        []AlbumViewModel `json:"albums"`
	AppearAlbums  []AlbumViewModel `json:"appear_albums"`
	HasRoleAlbums []AlbumViewModel `json:"has_role_albums"`

	AllTracks        []MinimalTrackViewModel `json:"all_tracks"`
	AllAppearTracks  []MinimalTrackViewModel `json:"all_appear_tracks"`
	AllHasRoleTracks []MinimalTrackViewModel `json:"all_has_role_tracks"`
}

func ConvertToArtistsViewModel(
	artists []entities.Artist,
) []ArtistViewModel {
	artistsViewModels := make([]ArtistViewModel, len(artists))

	for i, artist := range artists {
		artist.Albums = nil
		artist.AllTracks = nil

		artist.AppearAlbums = nil
		artist.AllAppearTracks = nil

		artist.HasRoleAlbums = nil
		artist.AllHasRoleTracks = nil

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

	allAppearTracksViewModels := make([]MinimalTrackViewModel, len(artist.AllAppearTracks))

	for i, track := range artist.AllAppearTracks {
		allAppearTracksViewModels[i] = ConvertToMinimalTrackViewModel(track)
	}

	allHasRoleTracksViewModels := make([]MinimalTrackViewModel, len(artist.AllHasRoleTracks))

	for i, track := range artist.AllHasRoleTracks {
		allHasRoleTracksViewModels[i] = ConvertToMinimalTrackViewModel(track)
	}

	albumsViewModels := make([]AlbumViewModel, len(artist.Albums))

	for i, album := range artist.Albums {
		album.Tracks = nil

		albumsViewModels[i] = ConvertToAlbumViewModel(album)
	}

	appearAlbumsViewModels := make([]AlbumViewModel, len(artist.AppearAlbums))

	for i, album := range artist.AppearAlbums {
		album.Tracks = nil

		appearAlbumsViewModels[i] = ConvertToAlbumViewModel(album)
	}

	hasRoleAlbumsViewModels := make([]AlbumViewModel, len(artist.HasRoleAlbums))

	for i, album := range artist.HasRoleAlbums {
		album.Tracks = nil

		hasRoleAlbumsViewModels[i] = ConvertToAlbumViewModel(album)
	}

	return ArtistViewModel{
		Id: artist.Id,

		UserId: artist.UserId,

		Name: artist.Name,

		Albums:        albumsViewModels,
		AppearAlbums:  appearAlbumsViewModels,
		HasRoleAlbums: hasRoleAlbumsViewModels,

		AllTracks:        allTracksViewModels,
		AllAppearTracks:  allAppearTracksViewModels,
		AllHasRoleTracks: allHasRoleTracksViewModels,
	}
}

type MinimalArtistViewModel struct {
	Id string `json:"id"`

	Name string `json:"name"`
}

func ConvertToMinimalArtistsViewModel(
	artists []string,
) []MinimalArtistViewModel {
	minimalArtistsViewModels := make([]MinimalArtistViewModel, len(artists))

	for i, artist := range artists {
		minimalArtistsViewModels[i] = ConvertToMinimalArtistViewModel(artist)
	}

	return minimalArtistsViewModels
}

func ConvertToMinimalArtistViewModel(
	artist string,
) MinimalArtistViewModel {
	artistId := ""

	if id, err := entities.GenerateArtistId(artist); err == nil {
		artistId = id
	}

	return MinimalArtistViewModel{
		Id:   artistId,
		Name: artist,
	}
}
