package playlist_usecase

import (
	"strings"

	"gungun974.com/melodink-server/internal/layers/domain/entities"
	"gungun974.com/melodink-server/internal/models"
)

func (u *PlaylistUsecase) ListAllAlbums() (models.APIResponse, error) {
	tracks, err := u.trackRepository.GetAllTracks()
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	playlists := []entities.Playlist{}

outerloop:
	for _, track := range tracks {
		if len(strings.TrimSpace(track.Album)) == 0 {
			continue
		}

		for i, playlist := range playlists {
			if playlist.Name == track.Album &&
				playlist.AlbumArtist == track.Metadata.AlbumArtist {
				playlists[i].Tracks = append(playlists[i].Tracks, track)
				continue outerloop
			}
		}

		playlists = append(playlists, entities.Playlist{
			Id:          -1,
			Name:        track.Album,
			Description: "",

			AlbumArtist: track.Metadata.AlbumArtist,

			Type: entities.AlbumPlaylistType,

			Tracks: []entities.Track{
				track,
			},
		})
	}

	return u.playlistPresenter.ShowAllPlaylists(playlists), nil
}
