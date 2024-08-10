package repository

import (
	"crypto/md5"
	"encoding/hex"
	"errors"
	"strings"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/jmoiron/sqlx"
)

var AlbumNotFoundError = errors.New("Album is not found")

func NewAlbumRepository(
	db *sqlx.DB, trackRepository TrackRepository,
) AlbumRepository {
	return AlbumRepository{
		Database:        db,
		trackRepository: trackRepository,
	}
}

type AlbumRepository struct {
	Database        *sqlx.DB
	trackRepository TrackRepository
}

func (r *AlbumRepository) getVirtualAlbumFromTrack(track entities.Track) (string, error) {
	if len(strings.TrimSpace(track.Metadata.Album)) == 0 {
		return "", errors.New("This track has no album")
	}

	rawId := "a#" + strings.ReplaceAll(
		track.Metadata.Album,
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

func (r *AlbumRepository) GroupTracksInAlbums(
	userId *int,
	tracks []entities.Track,
) []entities.Album {
	albums := []entities.Album{}

outerloop:
	for _, track := range tracks {
		albumId, err := r.getVirtualAlbumFromTrack(track)
		if err != nil {
			continue
		}

		for i, album := range albums {
			if album.Id == albumId {
				albums[i].Tracks = append(albums[i].Tracks, track)
				continue outerloop
			}
		}

		albums = append(albums, entities.Album{
			Id: albumId,

			UserId: userId,

			Name: track.Metadata.Album,

			AlbumArtist: track.Metadata.AlbumArtist,

			Tracks: []entities.Track{
				track,
			},
		})
	}

	return albums
}

func (r *AlbumRepository) GetAllAlbumsFromUser(userId int) ([]entities.Album, error) {
	tracks, err := r.trackRepository.GetAllTracksFromUser(userId)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	return r.GroupTracksInAlbums(&userId, tracks), nil
}

func (r *AlbumRepository) GetAlbumByIdFromUser(userId int, albumId string) (entities.Album, error) {
	tracks, err := r.trackRepository.GetAllTracksFromUser(userId)
	if err != nil {
		return entities.Album{}, entities.NewInternalError(err)
	}

	album := entities.Album{
		Id: albumId,

		UserId: &userId,

		Tracks: []entities.Track{},
	}

	for _, track := range tracks {
		albumId, err := r.getVirtualAlbumFromTrack(track)
		if err != nil {
			continue
		}

		if album.Id == albumId {
			album.Tracks = append(album.Tracks, track)
		}

	}

	if len(album.Tracks) == 0 {
		return entities.Album{}, AlbumNotFoundError
	}

	album.Name = album.Tracks[0].Metadata.Album

	album.AlbumArtist = album.Tracks[0].Metadata.AlbumArtist

	return album, nil
}
