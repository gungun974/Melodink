package repository

import (
	"errors"
	"sync"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/jmoiron/sqlx"
)

var AlbumNotFoundError = errors.New("Album is not found")

var albumCacheMutex = sync.Mutex{}

var allAlbumsCache = map[int][]entities.Album{}

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

func (r *AlbumRepository) GroupTracksInAlbums(
	userId *int,
	tracks []entities.Track,
) []entities.Album {
	albums := []entities.Album{}

outerloop:
	for _, track := range tracks {
		albumId, err := track.Metadata.GetVirtualAlbumId()
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

			AlbumArtists: track.Metadata.GetVirtualAlbumArtists(),

			Tracks: []entities.Track{
				track,
			},
		})
	}

	return albums
}

func (r *AlbumRepository) GetAllAlbumsFromUser(userId int) ([]entities.Album, error) {
	albumCacheMutex.Lock()
	defer albumCacheMutex.Unlock()

	if cache, ok := allAlbumsCache[userId]; ok {
		return cache, nil
	}

	tracks, err := r.trackRepository.GetAllTracksFromUser(userId)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	albums := r.GroupTracksInAlbums(&userId, tracks)

	allAlbumsCache[userId] = albums

	return albums, nil
}

func (r *AlbumRepository) GetAlbumByIdFromUser(userId int, albumId string) (entities.Album, error) {
	albums, err := r.GetAllAlbumsFromUser(userId)
	if err != nil {
		return entities.Album{}, entities.NewInternalError(err)
	}

	for _, album := range albums {
		if album.Id == albumId {
			return album, nil
		}
	}

	return entities.Album{}, AlbumNotFoundError
}

func invalidateAlbumCache() {
	albumCacheMutex.Lock()
	defer albumCacheMutex.Unlock()

	allAlbumsCache = map[int][]entities.Album{}

	invalidateArtistCache()
}
