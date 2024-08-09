package view_models

import (
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type PlaylistViewModel struct {
	Id int `json:"id"`

	UserId *int `json:"user_id"`

	Name        string `json:"name"`
	Description string `json:"description"`

	Tracks []MinimalTrackViewModel `json:"tracks"`
}

func ConvertToPlaylistViewModel(
	playlist entities.Playlist,
) PlaylistViewModel {
	tracksViewModels := make([]MinimalTrackViewModel, len(playlist.Tracks))

	for i, track := range playlist.Tracks {
		tracksViewModels[i] = ConvertToMinimalTrackViewModel(track)
	}

	return PlaylistViewModel{
		Id: playlist.Id,

		UserId: playlist.UserId,

		Name:        playlist.Name,
		Description: playlist.Description,

		Tracks: tracksViewModels,
	}
}
