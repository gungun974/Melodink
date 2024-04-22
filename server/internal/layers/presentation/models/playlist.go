package view_models

import "gungun974.com/melodink-server/internal/layers/domain/entities"

type PlaylistJson struct {
	Id          int    `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`

	AlbumArtist string `json:"album_artist"`

	Type entities.PlaylistType `json:"type"`

	Tracks []TrackJson `json:"tracks"`
}

func ConvertToPlaylistJson(
	playlist entities.Playlist,
) PlaylistJson {
	tracks := make([]TrackJson, len(playlist.Tracks))

	for i, track := range playlist.Tracks {
		tracks[i] = ConvertToTrackJson(track)
	}

	return PlaylistJson{
		Id:          playlist.Id,
		Name:        playlist.Name,
		Description: playlist.Description,
		Type:        playlist.Type,
		AlbumArtist: playlist.AlbumArtist,

		Tracks: tracks,
	}
}
