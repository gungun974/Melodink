package presenter_impl

import (
	"gungun974.com/melodink-server/internal/layers/domain/entities"
	presenter "gungun974.com/melodink-server/internal/layers/domain/presenters"
	"gungun974.com/melodink-server/pb"
)

type PlaylistPresenterImpl struct{}

func NewPlaylistPresenterImpl() presenter.PlaylistPresenter {
	return &PlaylistPresenterImpl{}
}

func (p *PlaylistPresenterImpl) ShowAllPlaylists(
	playlists []entities.Playlist,
) *pb.PlaylistList {
	pbPlaylists := make([]*pb.Playlist, len(playlists))

	for i, playlist := range playlists {
		var playlistType pb.PlaylistType

		switch playlist.Type {
		case entities.CustomPlaylistType:
			playlistType = pb.PlaylistType_CUSTOM
		case entities.AlbumPlaylistType:
			playlistType = pb.PlaylistType_ALBUM
		case entities.ArtistPlaylistType:
			playlistType = pb.PlaylistType_ARTIST
		}

		pbPlaylists[i] = &pb.Playlist{
			Id:          int32(playlist.Id),
			Name:        playlist.Name,
			Description: playlist.Description,
			Type:        playlistType,
			AlbumArtist: playlist.AlbumArtist,
		}
	}

	return &pb.PlaylistList{
		Playlists: pbPlaylists,
	}
}
