package repository_impl

import (
	"crypto/md5"
	"encoding/hex"
	"errors"
	"strings"

	"github.com/jmoiron/sqlx"
	"gungun974.com/melodink-server/internal/layers/domain/entities"
	"gungun974.com/melodink-server/internal/layers/domain/repository"
)

func NewPlaylistRepository(
	db *sqlx.DB, trackRepository repository.TrackRepository,
) repository.PlaylistRepository {
	return &PlaylistRepositoryImpl{
		Database:        db,
		trackRepository: trackRepository,
	}
}

type PlaylistRepositoryImpl struct {
	Database        *sqlx.DB
	trackRepository repository.TrackRepository
}

func (r *PlaylistRepositoryImpl) getVirtualAlbumFromTrack(track entities.Track) (string, error) {
	if len(strings.TrimSpace(track.Album)) == 0 {
		return "", errors.New("This track has no album")
	}

	rawId := "a#" + strings.ReplaceAll(
		track.Album,
		"#",
		"##",
	) + "r#" + strings.ReplaceAll(
		track.Metadata.AlbumArtist,
		"#",
		"##",
	)

	hasher := md5.New()

	hasher.Write([]byte(rawId))

	hashBytes := hasher.Sum(nil)

	hashString := hex.EncodeToString(hashBytes)

	return hashString, nil
}

func (r *PlaylistRepositoryImpl) GetAllAlbums() ([]entities.Playlist, error) {
	tracks, err := r.trackRepository.GetAllTracks()
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	playlists := []entities.Playlist{}

outerloop:
	for _, track := range tracks {
		albumId, err := r.getVirtualAlbumFromTrack(track)
		if err != nil {
			continue
		}

		for i, playlist := range playlists {
			if playlist.Id == albumId {
				playlists[i].Tracks = append(playlists[i].Tracks, track)
				continue outerloop
			}
		}

		playlists = append(playlists, entities.Playlist{
			Id:          albumId,
			Name:        track.Album,
			Description: "",

			AlbumArtist: track.Metadata.AlbumArtist,

			Type: entities.AlbumPlaylistType,

			Tracks: []entities.Track{
				track,
			},
		})
	}

	return playlists, nil
}

func (r *PlaylistRepositoryImpl) GetAlbumById(id string) (entities.Playlist, error) {
	tracks, err := r.trackRepository.GetAllTracks()
	if err != nil {
		return entities.Playlist{}, entities.NewInternalError(err)
	}

	playlist := entities.Playlist{
		Id:          id,
		Description: "",

		Type:   entities.AlbumPlaylistType,
		Tracks: []entities.Track{},
	}

	for _, track := range tracks {
		albumId, err := r.getVirtualAlbumFromTrack(track)
		if err != nil {
			continue
		}

		if playlist.Id == albumId {
			playlist.Tracks = append(playlist.Tracks, track)
		}

	}

	if len(playlist.Tracks) == 0 {
		return entities.Playlist{}, repository.PlaylistNotFoundError
	}

	playlist.Name = playlist.Tracks[0].Album

	playlist.AlbumArtist = playlist.Tracks[0].Metadata.AlbumArtist

	return playlist, nil
}
