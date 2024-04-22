package presenter

import (
	"gungun974.com/melodink-server/internal/layers/domain/entities"
	"gungun974.com/melodink-server/pb"
)

type PlaylistPresenter interface {
	ShowAllPlaylists(playlists []entities.Playlist) *pb.PlaylistList
}
