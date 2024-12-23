package view_models

import (
	"context"
	"time"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type AlbumViewModel struct {
	Id string `json:"id"`

	UserId *int `json:"user_id"`

	Name string `json:"name"`

	AlbumArtists []MinimalArtistViewModel `json:"album_artists"`

	Tracks []MinimalTrackViewModel `json:"tracks"`

	LastTrackDateAdded string `json:"last_track_date_added"`
}

func ConvertToAlbumsViewModel(
	ctx context.Context,
	albums []entities.Album,
	showTracks bool,
) []AlbumViewModel {
	albumsViewModels := make([]AlbumViewModel, len(albums))

	for i, album := range albums {
		if !showTracks {
			album.Tracks = nil
		}

		albumsViewModels[i] = ConvertToAlbumViewModel(ctx, album)

		if !showTracks {
			lastTrack := entities.Track{}

			for _, track := range albums[i].Tracks {
				if track.DateAdded.After(lastTrack.DateAdded) {
					lastTrack = track
				}
			}

			albumsViewModels[i].LastTrackDateAdded = lastTrack.DateAdded.UTC().
				Format(time.RFC3339)

		}
	}

	return albumsViewModels
}

func ConvertToAlbumViewModel(
	ctx context.Context,
	album entities.Album,
) AlbumViewModel {
	tracksViewModels := make([]MinimalTrackViewModel, len(album.Tracks))

	lastTrack := entities.Track{}

	for i, track := range album.Tracks {
		tracksViewModels[i] = ConvertToMinimalTrackViewModel(ctx, track)
		if track.DateAdded.After(lastTrack.DateAdded) {
			lastTrack = track
		}
	}

	return AlbumViewModel{
		Id: album.Id,

		UserId: album.UserId,

		Name: album.Name,

		AlbumArtists: ConvertToMinimalArtistsViewModel(album.AlbumArtists),

		Tracks: tracksViewModels,

		LastTrackDateAdded: lastTrack.DateAdded.UTC().Format(time.RFC3339),
	}
}
