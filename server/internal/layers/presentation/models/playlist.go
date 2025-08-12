package view_models

import (
	"context"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type PlaylistViewModel struct {
	Id int `json:"id"`

	UserId *int `json:"user_id"`

	Name        string `json:"name"`
	Description string `json:"description"`

	CoverSignature string `json:"cover_signature"`

	Tracks []int `json:"tracks"`
}

func ConvertToPlaylistViewModels(
	ctx context.Context,
	playlists []entities.Playlist,
) []PlaylistViewModel {
	playlistsViewModels := make([]PlaylistViewModel, len(playlists))

	for i, playlist := range playlists {
		playlistsViewModels[i] = ConvertToPlaylistViewModel(ctx, playlist)
	}

	return playlistsViewModels
}

func ConvertToPlaylistViewModel(
	ctx context.Context,
	playlist entities.Playlist,
) PlaylistViewModel {
	tracks := make([]int, len(playlist.Tracks))

	for i, track := range playlist.Tracks {
		tracks[i] = track.Id
	}

	return PlaylistViewModel{
		Id: playlist.Id,

		UserId: playlist.UserId,

		Name:        playlist.Name,
		Description: playlist.Description,

		CoverSignature: playlist.CoverSignature,

		Tracks: tracks,
	}
}
