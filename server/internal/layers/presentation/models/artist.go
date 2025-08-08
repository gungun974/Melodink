package view_models

import (
	"context"
	"time"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type ArtistViewModel struct {
	Id int `json:"id"`

	UserId *int `json:"user_id"`

	Name string `json:"name"`

	Albums        []AlbumViewModel `json:"albums"`
	AppearAlbums  []AlbumViewModel `json:"appear_albums"`
	HasRoleAlbums []AlbumViewModel `json:"has_role_albums"`

	AllTracks        []MinimalTrackViewModel `json:"all_tracks"`
	AllAppearTracks  []MinimalTrackViewModel `json:"all_appear_tracks"`
	AllHasRoleTracks []MinimalTrackViewModel `json:"all_has_role_tracks"`

	LastTrackDateAdded string `json:"last_track_date_added"`
}

func ConvertToArtistsViewModel(
	ctx context.Context,
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

		artistsViewModels[i] = ConvertToArtistViewModel(ctx, artist)

		lastTrack := entities.Track{}

		for _, track := range artists[i].AllTracks {
			if track.DateAdded.After(lastTrack.DateAdded) {
				lastTrack = track
			}
		}

		for _, track := range artists[i].AllAppearTracks {
			if track.DateAdded.After(lastTrack.DateAdded) {
				lastTrack = track
			}
		}

		artistsViewModels[i].LastTrackDateAdded = lastTrack.DateAdded.UTC().
			Format(time.RFC3339)

	}

	return artistsViewModels
}

func ConvertToArtistViewModel(
	ctx context.Context,
	artist entities.Artist,
) ArtistViewModel {
	allTracksViewModels := make([]MinimalTrackViewModel, len(artist.AllTracks))

	lastTrack := entities.Track{}

	for i, track := range artist.AllTracks {
		allTracksViewModels[i] = ConvertToMinimalTrackViewModel(ctx, track)
		if track.DateAdded.After(lastTrack.DateAdded) {
			lastTrack = track
		}
	}

	allAppearTracksViewModels := make([]MinimalTrackViewModel, len(artist.AllAppearTracks))

	for i, track := range artist.AllAppearTracks {
		allAppearTracksViewModels[i] = ConvertToMinimalTrackViewModel(ctx, track)
		if track.DateAdded.After(lastTrack.DateAdded) {
			lastTrack = track
		}
	}

	allHasRoleTracksViewModels := make([]MinimalTrackViewModel, len(artist.AllHasRoleTracks))

	for i, track := range artist.AllHasRoleTracks {
		allHasRoleTracksViewModels[i] = ConvertToMinimalTrackViewModel(ctx, track)
	}

	albumsViewModels := make([]AlbumViewModel, len(artist.Albums))

	for i, album := range artist.Albums {
		album.Tracks = nil

		albumsViewModels[i] = ConvertToAlbumViewModel(ctx, album)
	}

	appearAlbumsViewModels := make([]AlbumViewModel, len(artist.AppearAlbums))

	for i, album := range artist.AppearAlbums {
		album.Tracks = nil

		appearAlbumsViewModels[i] = ConvertToAlbumViewModel(ctx, album)
	}

	hasRoleAlbumsViewModels := make([]AlbumViewModel, len(artist.HasRoleAlbums))

	for i, album := range artist.HasRoleAlbums {
		album.Tracks = nil

		hasRoleAlbumsViewModels[i] = ConvertToAlbumViewModel(ctx, album)
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

		LastTrackDateAdded: lastTrack.DateAdded.UTC().
			Format(time.RFC3339),
	}
}

type MinimalArtistViewModel struct {
	Id int `json:"id"`

	Name string `json:"name"`
}

func ConvertToMinimalArtistsViewModel(
	artists []entities.Artist,
) []MinimalArtistViewModel {
	minimalArtistsViewModels := make([]MinimalArtistViewModel, len(artists))

	for i, artist := range artists {
		minimalArtistsViewModels[i] = ConvertToMinimalArtistViewModel(artist)
	}

	return minimalArtistsViewModels
}

func ConvertToMinimalArtistViewModel(
	artist entities.Artist,
) MinimalArtistViewModel {
	return MinimalArtistViewModel{
		Id:   artist.Id,
		Name: artist.Name,
	}
}
