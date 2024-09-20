package repository

import (
	"crypto/md5"
	"encoding/hex"
	"errors"
	"strings"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/jmoiron/sqlx"
)

var ArtistNotFoundError = errors.New("Artist is not found")

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

func (r *ArtistRepository) getVirtualArtistFromTrack(track entities.Track) (string, error) {
	artist := track.Metadata.GetVirtualAlbumArtist()

	if len(artist) == 0 {
		return "", errors.New("This track has no artist or album artist")
	}

	rawId := "r#" + strings.ReplaceAll(
		artist,
		"#",
		"##",
	)

	hasher := md5.New()

	hasher.Write([]byte(rawId))

	hashBytes := hasher.Sum(nil)

	hashString := hex.EncodeToString(hashBytes)

	return hashString, nil
}

func (r *ArtistRepository) GetAllArtistsFromUser(userId int) ([]entities.Artist, error) {
	tracks, err := r.trackRepository.GetAllTracksFromUser(userId)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	artists := []entities.Artist{}

outerloop:
	for _, track := range tracks {
		artistId, err := r.getVirtualArtistFromTrack(track)
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

			Name: track.Metadata.GetVirtualAlbumArtist(),

			AllTracks: []entities.Track{
				track,
			},
		})
	}

	for i, artist := range artists {
		artists[i].Albums = r.albumRepository.GroupTracksInAlbums(&userId, artist.AllTracks)
	}

	return artists, nil
}

func (r *ArtistRepository) GetArtistByIdFromUser(
	userId int,
	artistId string,
) (entities.Artist, error) {
	tracks, err := r.trackRepository.GetAllTracksFromUser(userId)
	if err != nil {
		return entities.Artist{}, entities.NewInternalError(err)
	}

	artist := entities.Artist{
		Id: artistId,

		UserId: &userId,

		AllTracks: []entities.Track{},
	}

	for _, track := range tracks {
		artistId, err := r.getVirtualArtistFromTrack(track)
		if err != nil {
			continue
		}

		if artist.Id == artistId {
			artist.AllTracks = append(artist.AllTracks, track)
		}

	}

	if len(artist.AllTracks) == 0 {
		return entities.Artist{}, ArtistNotFoundError
	}

	artist.Name = artist.AllTracks[0].Metadata.GetVirtualAlbumArtist()

	artist.Albums = r.albumRepository.GroupTracksInAlbums(&userId, artist.AllTracks)

	return artist, nil
}
