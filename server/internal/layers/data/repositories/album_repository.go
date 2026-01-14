package repositories

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

var AlbumNotFoundError = errors.New("Album is not found")

func NewAlbumRepository(
	db *sqlx.DB,
) AlbumRepository {
	return AlbumRepository{
		Database: db,

		getAlbumOrCreateMutex: &sync.Mutex{},
	}
}

type AlbumRepository struct {
	Database *sqlx.DB

	getAlbumOrCreateMutex *sync.Mutex
}

func (r *AlbumRepository) GetAllAlbumsFromUser(userId int) ([]entities.Album, error) {
	m := data_models.AlbumModels{}

	err := r.Database.Select(&m, `
    SELECT * FROM albums WHERE user_id = ?
  `, userId)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	albums := m.ToAlbums()

	err = r.LoadArtistsInAlbums(albums)
	if err != nil {
		return nil, err
	}

	return albums, nil
}

func (r *AlbumRepository) GetAllAlbumsFromUserSince(
	userId int,
	since time.Time,
) ([]entities.Album, error) {
	m := data_models.AlbumModels{}

	err := r.Database.Select(&m, `
    SELECT * FROM albums WHERE user_id = ? AND (COALESCE(updated_at, created_at) >= ?)
  `, userId, since.UTC())
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	albums := m.ToAlbums()

	err = r.LoadArtistsInAlbums(albums)
	if err != nil {
		return nil, err
	}

	return albums, nil
}

func (r *AlbumRepository) GetAlbumById(id int) (*entities.Album, error) {
	m := data_models.AlbumModel{}

	err := r.Database.Get(&m, `
    SELECT *
    FROM albums
    WHERE id = ?
  `, id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, AlbumNotFoundError
		}
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	album := m.ToAlbum()

	err = r.LoadTracksInAlbum(&album)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	err = r.LoadArtistsInAlbum(&album)
	if err != nil {
		return nil, err
	}

	return &album, nil
}

func (r *AlbumRepository) GetAlbumByName(
	name string,
	albumArtists []entities.Artist,
	userId int,
) (*entities.Album, error) {
	m := data_models.AlbumModel{}

	if len(albumArtists) == 0 {
		err := r.Database.Get(&m,
			`
		SELECT albums.*
		FROM albums
		JOIN album_artist ON album_artist.album_id = albums.id
		WHERE LOWER(albums.name) = LOWER(?) 
			AND albums.user_id = ?
		GROUP BY albums.id
		HAVING COUNT(DISTINCT album_artist.artist_id) = 0;
	`, name, userId)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				return nil, AlbumNotFoundError
			}
			logger.DatabaseLogger.Error(err)
			return nil, err
		}
	} else {
		artistIds := make([]int, len(albumArtists))

		for i, artist := range albumArtists {
			artistIds[i] = artist.Id
		}

		reqQuery, reqArgs, err := sqlx.In(`
		SELECT albums.*
		FROM albums
		JOIN album_artist ON album_artist.album_id = albums.id
		WHERE LOWER(albums.name) = LOWER(?) 
			AND albums.user_id = ?
		GROUP BY albums.id
		HAVING COUNT(DISTINCT album_artist.artist_id) = ?
			AND COUNT(DISTINCT CASE WHEN album_artist.artist_id IN (?) THEN album_artist.artist_id END) = ?;
	`, name, userId, len(artistIds), artistIds, len(artistIds))
		if err != nil {
			return nil, err
		}
		reqQuery = r.Database.Rebind(reqQuery)

		err = r.Database.Get(&m, reqQuery, reqArgs...)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				return nil, AlbumNotFoundError
			}
			logger.DatabaseLogger.Error(err)
			return nil, err
		}
	}

	album := m.ToAlbum()

	err := r.LoadTracksInAlbum(&album)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	err = r.LoadArtistsInAlbum(&album)
	if err != nil {
		return nil, err
	}

	return &album, nil
}

func (r *AlbumRepository) LoadTracksInAlbum(album *entities.Album) error {
	m := data_models.TracksModels{}

	err := r.Database.Select(&m, `
		SELECT tracks.*
		FROM tracks
		JOIN track_album ON tracks.id = track_album.track_id
		WHERE track_album.album_id = ? AND pending_import = 0
  `, album.Id)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	album.Tracks = m.ToTracks()

	return nil
}

func (r *AlbumRepository) LoadTracksInAlbums(albums []entities.Album) error {
	for i := range albums {
		err := r.LoadTracksInAlbum(&albums[i])
		if err != nil {
			return nil
		}
	}

	return nil
}

func (r *AlbumRepository) LoadArtistsInAlbum(album *entities.Album) error {
	m := data_models.ArtistModels{}

	err := r.Database.Select(&m, `
		SELECT artists.*
		FROM artists
		JOIN album_artist ON artists.id = album_artist.artist_id
		WHERE album_artist.album_id = ?
		ORDER BY album_artist.artist_pos ASC
  `, album.Id)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	album.Artists = m.ToArtists()

	return nil
}

func (r *AlbumRepository) LoadArtistsInAlbums(albums []entities.Album) error {
	for i := range albums {
		err := r.LoadArtistsInAlbum(&albums[i])
		if err != nil {
			return nil
		}
	}

	return nil
}

func (r *AlbumRepository) CreateAlbum(album *entities.Album) error {
	m := data_models.AlbumModel{}

	err := r.Database.Get(
		&m,
		`
    INSERT INTO albums
      (
        user_id,

        name,
				created_at
      )
    VALUES
      (
        ?,
        ?,
				STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
      )
    RETURNING *
  `,
		album.UserId,

		album.Name,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	*album = m.ToAlbum()

	return nil
}

func (r AlbumRepository) GetAlbumByNameOrCreate(
	name string,
	albumArtists []entities.Artist,
	userId int,
) (*entities.Album, error) {
	r.getAlbumOrCreateMutex.Lock()
	defer r.getAlbumOrCreateMutex.Unlock()

	album, err := r.GetAlbumByName(name, albumArtists, userId)

	if err != nil && errors.Is(err, AlbumNotFoundError) {
		album = &entities.Album{
			UserId: &userId,
			Name:   name,
		}

		err = r.CreateAlbum(album)
		if err != nil {
			logger.DatabaseLogger.Error(err)
			return nil, entities.NewInternalError(err)
		}

		album.Artists = albumArtists

		err = r.SetAlbumArtists(album)
	}

	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, entities.NewInternalError(err)
	}

	return album, nil
}

func (r *AlbumRepository) UpdateAlbum(album *entities.Album) error {
	m := data_models.AlbumModel{}

	err := r.Database.Get(
		&m,
		`
    UPDATE albums
    SET
        user_id = ?,

        name = ?,
      	updated_at = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE
      id = ?
    RETURNING *
  `,
		album.UserId,

		album.Name,
		album.Id,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	*album = m.ToAlbum()

	return nil
}

func (r AlbumRepository) AddAlbumTracks(album *entities.Album) error {
	if len(album.Tracks) == 0 {
		return nil
	}

	tx, err := r.Database.Beginx()
	if err != nil {
		return err
	}

	trackIds := make([]int, len(album.Tracks))

	for i, track := range album.Tracks {
		trackIds[i] = track.Id
	}

	insertQuery := `INSERT OR IGNORE INTO track_album (album_id, track_id, album_pos) VALUES `
	args := make([]any, 0, len(trackIds)*3)
	valuePlaceholders := ""

	for i, trackId := range trackIds {
		var maxPos int
		err = tx.QueryRow(
			`SELECT COALESCE(MAX(album_pos), 0) FROM track_album WHERE track_id = ?`,
			trackId,
		).Scan(&maxPos)
		if err != nil {
			_ = tx.Rollback()
			return err
		}

		if i > 0 {
			valuePlaceholders += ", "
		}
		valuePlaceholders += "(?, ?, ?)"
		args = append(args, album.Id, trackId, maxPos+1)
	}

	insertQuery += valuePlaceholders

	_, err = tx.Exec(insertQuery, args...)
	if err != nil {
		_ = tx.Rollback()
		return err
	}

	updateQuery, updateArgs, err := sqlx.In(`
		UPDATE tracks SET updated_at = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW') WHERE id IN (?)
	`, trackIds)
	if err != nil {
		_ = tx.Rollback()
		return err
	}
	updateQuery = tx.Rebind(updateQuery)

	_, err = tx.Exec(updateQuery, updateArgs...)
	if err != nil {
		_ = tx.Rollback()
		return err
	}

	if err := tx.Commit(); err != nil {
		return err
	}

	return nil
}

func (r AlbumRepository) RemoveAlbumTracks(album *entities.Album) error {
	if len(album.Tracks) == 0 {
		return nil
	}

	tx, err := r.Database.Beginx()
	if err != nil {
		return err
	}

	trackIds := make([]int, len(album.Tracks))

	for i, track := range album.Tracks {
		trackIds[i] = track.Id
	}

	delQuery, delArgs, err := sqlx.In(`
		DELETE FROM track_album
		WHERE album_id = ? AND track_id IN (?)
		RETURNING track_id
	`, album.Id, trackIds)
	if err != nil {
		return err
	}
	delQuery = tx.Rebind(delQuery)

	removedTracks, err := tx.Query(delQuery, delArgs...)
	if err != nil {
		return err
	}
	defer removedTracks.Close()

	updatedTracks := []int{}

	for removedTracks.Next() {
		var id int
		if err := removedTracks.Scan(&id); err != nil {
			_ = tx.Rollback()
			return err
		}
		updatedTracks = append(updatedTracks, id)
	}

	updateQuery, updateArgs, err := sqlx.In(`
		UPDATE tracks SET updated_at = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW') WHERE id IN (?)
	`, updatedTracks)
	if err != nil {
		_ = tx.Rollback()
		return err
	}
	updateQuery = tx.Rebind(updateQuery)

	_, err = tx.Exec(updateQuery, updateArgs...)
	if err != nil {
		_ = tx.Rollback()
		return err
	}

	if err := tx.Commit(); err != nil {
		return err
	}

	return nil
}

func (r AlbumRepository) SetAlbumArtists(album *entities.Album) error {
	if len(album.Artists) == 0 {
		_, err := r.Database.Exec(`
			DELETE FROM album_artist
			WHERE album_id = ?
		`, album.Id)
		if err != nil {
			return err
		}

		return nil
	}

	tx, err := r.Database.Beginx()
	if err != nil {
		return err
	}

	artistIds := make([]int, len(album.Artists))

	for i, artist := range album.Artists {
		artistIds[i] = artist.Id
	}

	// Remove Extra

	delQuery, delArgs, err := sqlx.In(`
		DELETE FROM album_artist
		WHERE album_id = ? AND artist_id NOT IN (?)
	`, album.Id, artistIds)
	if err != nil {
		_ = tx.Rollback()
		return err
	}
	delQuery = tx.Rebind(delQuery)

	_, err = tx.Exec(delQuery, delArgs...)
	if err != nil {
		_ = tx.Rollback()
		return err
	}

	// Insert Missing

	insertQuery := `INSERT OR IGNORE INTO album_artist (album_id, artist_id) VALUES `
	args := make([]any, 0, len(artistIds)*2)
	valuePlaceholders := ""

	for i, artistId := range artistIds {
		if i > 0 {
			valuePlaceholders += ", "
		}
		valuePlaceholders += "(?, ?)"
		args = append(args, album.Id, artistId)
	}

	insertQuery += valuePlaceholders

	_, err = tx.Exec(insertQuery, args...)
	if err != nil {
		_ = tx.Rollback()
		return err
	}

	// Set Order

	for i, artistId := range artistIds {
		_, err = tx.Exec(
			"UPDATE album_artist SET artist_pos = ? WHERE album_id = ? AND artist_id = ?",
			i,
			album.Id,
			artistId,
		)
		if err != nil {
			_ = tx.Rollback()
			return err
		}
	}

	// Update

	_, err = tx.Exec(
		"UPDATE albums SET updated_at = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW') WHERE id = ?",
		album.Id,
	)
	if err != nil {
		_ = tx.Rollback()
		return err
	}

	if err := tx.Commit(); err != nil {
		return err
	}

	return nil
}

func (r *AlbumRepository) DeleteAlbum(album *entities.Album) error {
	m := data_models.AlbumModel{}

	tx, err := r.Database.Beginx()
	if err != nil {
		return err
	}

	err = tx.Get(&m, `
    DELETE FROM
      albums
    WHERE 
      id = ?
    RETURNING *
  `,
		album.Id,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		_ = tx.Rollback()
		return err
	}

	_, err = tx.Exec("INSERT INTO deleted_albums (id) VALUES (?)", album.Id)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		_ = tx.Rollback()
		return err
	}

	if err := tx.Commit(); err != nil {
		return err
	}

	*album = m.ToAlbum()

	return nil
}

func (r *AlbumRepository) GetAllDeletedAlbumsSince(since time.Time) ([]int, error) {
	rows, err := r.Database.Query(`
    SELECT id FROM deleted_albums WHERE deleted_at >= datetime(?)
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
