package repository

import (
	"errors"
	"sync"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/jmoiron/sqlx"
)

var ArtistNotFoundError = errors.New("Artist is not found")

var artistCacheMutex = sync.Mutex{}

var allArtistsCache = map[int][]entities.Artist{}

func NewArtistRepository(
	db *sqlx.DB, trackRepository TrackRepository,
	albumRepository AlbumRepository,
) ArtistRepository {
	return ArtistRepository{
		Database:        db,
		trackRepository: trackRepository,
		albumRepository: albumRepository,
	}
}

type ArtistRepository struct {
	Database        *sqlx.DB
	trackRepository TrackRepository
	albumRepository AlbumRepository
}

func (r *ArtistRepository) GetAllArtistsFromUser(userId int) ([]entities.Artist, error) {
	artistCacheMutex.Lock()
	defer artistCacheMutex.Unlock()

	if cache, ok := allArtistsCache[userId]; ok {
		return cache, nil
	}

	tracks, err := r.trackRepository.GetAllTracksFromUser(userId)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	artists := []entities.Artist{}

	for _, track := range tracks {
	outerloop:
		for _, trackArtist := range track.Metadata.GetVirtualAlbumArtists() {
			artistId, err := entities.GenerateArtistId(trackArtist)
			if err != nil {
				continue
			}

			for i, artist := range artists {
				if artist.Id == artistId {
					artists[i].AllTracks = append(artists[i].AllTracks, track)
					continue outerloop
				}
			}

			artists = append(artists, entities.Artist{
				Id: artistId,

				UserId: &userId,

				Name: trackArtist,

				AllTracks: []entities.Track{
					track,
				},
				AllAppearTracks:  []entities.Track{},
				AllHasRoleTracks: []entities.Track{},
			})
		}
	}

	for _, track := range tracks {
	outerloop2:
		for _, trackArtist := range track.Metadata.Artists {
			artistId, err := entities.GenerateArtistId(trackArtist)
			if err != nil {
				continue
			}

			for i, artist := range artists {
				if artist.Id == artistId {
					artists[i].AllAppearTracks = append(artists[i].AllAppearTracks, track)
					continue outerloop2
				}
			}

			artists = append(artists, entities.Artist{
				Id: artistId,

				UserId: &userId,

				Name: trackArtist,

				AllTracks: []entities.Track{},
				AllAppearTracks: []entities.Track{
					track,
				},
				AllHasRoleTracks: []entities.Track{},
			})
		}
	}

	for _, track := range tracks {
	outerloop3:
		for _, role := range track.Metadata.ArtistsRoles {
			artistId, err := entities.GenerateArtistId(role.Artist)
			if err != nil {
				continue
			}

			for i, artist := range artists {
				if artist.Id == artistId {
					artists[i].AllHasRoleTracks = append(artists[i].AllHasRoleTracks, track)
					continue outerloop3
				}
			}

			artists = append(artists, entities.Artist{
				Id: artistId,

				UserId: &userId,

				Name: role.Artist,

				AllTracks:       []entities.Track{},
				AllAppearTracks: []entities.Track{},
				AllHasRoleTracks: []entities.Track{
					track,
				},
			})
		}
	}

	for i, artist := range artists {
		artists[i].Albums = r.albumRepository.GroupTracksInAlbums(
			&userId,
			artist.AllTracks,
		)

		artists[i].AppearAlbums = r.albumRepository.GroupTracksInAlbums(
			&userId,
			artist.AllAppearTracks,
		)

		artists[i].HasRoleAlbums = r.albumRepository.GroupTracksInAlbums(
			&userId,
			artist.AllHasRoleTracks,
		)
	}

	allArtistsCache[userId] = artists

	return artists, nil
}

func (r *ArtistRepository) GetArtistByIdFromUser(
	userId int,
	artistId string,
) (entities.Artist, error) {
	artists, err := r.GetAllArtistsFromUser(userId)
	if err != nil {
		return entities.Artist{}, entities.NewInternalError(err)
	}

	for _, artist := range artists {
		if artist.Id == artistId {
			return artist, nil
		}
	}

	return entities.Artist{}, ArtistNotFoundError
}

func invalidateArtistCache() {
	artistCacheMutex.Lock()
	defer artistCacheMutex.Unlock()

	allArtistsCache = map[int][]entities.Artist{}
}
