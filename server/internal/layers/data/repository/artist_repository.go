package repository

import (
	"database/sql"
	"errors"
	"sync"
	"time"

	data_models "github.com/gungun974/Melodink/server/internal/layers/data/models"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
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

		getArtistOrCreateMutex: &sync.Mutex{},
	}
}

type ArtistRepository struct {
	Database        *sqlx.DB
	trackRepository TrackRepository
	albumRepository AlbumRepository

	getArtistOrCreateMutex *sync.Mutex
}

func (r *ArtistRepository) GetAllArtistsFromUser(userId int) ([]entities.Artist, error) {
	m := data_models.ArtistModels{}

	err := r.Database.Select(&m, `
    SELECT * FROM artists WHERE user_id = ?
  `, userId)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	return m.ToArtists(), nil
}

func (r *ArtistRepository) GetAllArtistsFromUserSince(
	userId int,
	since time.Time,
) ([]entities.Artist, error) {
	m := data_models.ArtistModels{}

	err := r.Database.Select(&m, `
    SELECT * FROM artists WHERE user_id = ? AND (COALESCE(updated_at, created_at) >= ?)
  `, userId, since.UTC())
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	return m.ToArtists(), nil
}

func (r *ArtistRepository) GetArtistById(
	id int,
) (*entities.Artist, error) {
	m := data_models.ArtistModel{}

	err := r.Database.Get(&m, `
    SELECT *
    FROM artists
    WHERE id = ?
  `, id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ArtistNotFoundError
		}
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	artist := m.ToArtist()

	err = r.loadArtistSubData(&artist)
	if err != nil {
		return nil, err
	}

	return &artist, nil
}

func (r ArtistRepository) GetArtistByName(name string, userId int) (*entities.Artist, error) {
	m := data_models.ArtistModel{}

	err := r.Database.Get(&m, `
    SELECT *
    FROM artists
    WHERE LOWER(name) = LOWER(?) AND user_id = ?
  `, name, userId)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ArtistNotFoundError
		}
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	artist := m.ToArtist()

	err = r.loadArtistSubData(&artist)
	if err != nil {
		return nil, err
	}

	return &artist, nil
}

func (r *ArtistRepository) loadArtistSubData(artist *entities.Artist) error {
	m := data_models.AlbumModels{}

	err := r.Database.Select(&m, `
		SELECT albums.*
		FROM albums
		JOIN album_artist ON albums.id = album_artist.album_id
		WHERE album_artist.artist_id = ?
		ORDER BY album_artist.artist_pos ASC
  `, artist.Id)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	artist.Albums = m.ToAlbums()

	m2 := data_models.TracksModels{}

	err = r.Database.Select(&m2, `
		SELECT tracks.*
		FROM tracks
		JOIN track_artist ON tracks.id = track_artist.track_id
		WHERE track_artist.artist_id = ?
		ORDER BY track_artist.artist_pos ASC
  `, artist.Id)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	artist.AllTracks = m2.ToTracks()

	err = r.trackRepository.LoadAlbumsInTracks(artist.AllTracks)
	if err != nil {
		return err
	}

	artist.AppearAlbums = make([]entities.Album, 0)

	for _, track := range artist.AllTracks {
	skip:
		for _, album := range track.Albums {
			for _, addedAlbum := range artist.Albums {
				if album.Id == addedAlbum.Id {
					continue skip
				}
			}
			for _, addedAlbum := range artist.AppearAlbums {
				if album.Id == addedAlbum.Id {
					continue skip
				}
			}
			artist.AppearAlbums = append(artist.AppearAlbums, album)
		}
	}

	return nil
}

func (r *ArtistRepository) CreateArtist(artist *entities.Artist) error {
	m := data_models.ArtistModel{}

	err := r.Database.Get(
		&m,
		`
    INSERT INTO artists
      (
        user_id,

        name
      )
    VALUES
      (
        ?,
        ?
      )
    RETURNING *
  `,
		artist.UserId,

		artist.Name,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	*artist = m.ToArtist()

	return nil
}

func (r ArtistRepository) GetArtistByNameOrCreate(
	name string,
	userId int,
) (*entities.Artist, error) {
	r.getArtistOrCreateMutex.Lock()
	defer r.getArtistOrCreateMutex.Unlock()

	artist, err := r.GetArtistByName(name, userId)

	if err != nil && errors.Is(err, ArtistNotFoundError) {
		artist = &entities.Artist{
			UserId: &userId,
			Name:   name,
		}

		err = r.CreateArtist(artist)
	}

	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, entities.NewInternalError(err)
	}

	return artist, nil
}

func (r *ArtistRepository) UpdateArtist(artist *entities.Artist) error {
	m := data_models.ArtistModel{}

	err := r.Database.Get(
		&m,
		`
    UPDATE artists
    SET
        user_id = ?,

        name = ?,
      	updated_at = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE
      id = ?
    RETURNING *
  `,
		artist.UserId,

		artist.Name,
		artist.Id,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	*artist = m.ToArtist()

	return nil
}

func (r *ArtistRepository) DeleteArtist(artist *entities.Artist) error {
	m := data_models.ArtistModel{}

	tx, err := r.Database.Beginx()
	if err != nil {
		return err
	}

	err = tx.Get(&m, `
    DELETE FROM
      artists
    WHERE 
      id = ?
    RETURNING *
  `,
		artist.Id,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		_ = tx.Rollback()
		return err
	}

	_, err = tx.Exec("INSERT INTO deleted_artists (id) VALUES (?)", artist.Id)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		_ = tx.Rollback()
		return err
	}

	if err := tx.Commit(); err != nil {
		return err
	}

	*artist = m.ToArtist()

	return nil
}

func (r *ArtistRepository) GetAllDeletedArtistsSince(since time.Time) ([]int, error) {
	rows, err := r.Database.Query(`
    SELECT id FROM deleted_artists WHERE deleted_at >= datetime(?)
  `, since.UTC())
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}
	defer rows.Close()

	ids := []int{}

	for rows.Next() {
		var id int
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}

	return ids, nil
}
