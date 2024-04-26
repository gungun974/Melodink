package presenter

import (
	"gungun974.com/melodink-server/internal/layers/domain/entities"
	"gungun974.com/melodink-server/internal/models"
)

type PlaylistPresenter interface {
	ShowAllPlaylists(playlists []entities.Playlist) models.APIResponse

	ShowPlaylist(playlist entities.Playlist) models.APIResponse
}
