package controllers

import (
	playlist_usecase "gungun974.com/melodink-server/internal/layers/domain/usecases/playlist"
	"gungun974.com/melodink-server/pb"
)

type PlaylistController struct {
	playlistUsecase playlist_usecase.PlaylistUsecase
}

func NewPlaylistController(
	playlistUsecase playlist_usecase.PlaylistUsecase,
) PlaylistController {
	return PlaylistController{
		playlistUsecase,
	}
}

func (c *PlaylistController) ListAllAlbums() (*pb.PlaylistList, error) {
	return c.playlistUsecase.ListAllAlbums()
}
