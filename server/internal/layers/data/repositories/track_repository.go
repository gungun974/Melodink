package repositories

import (
	"database/sql"
	"encoding/json"
	"errors"
	"time"

	data_models "github.com/gungun974/Melodink/server/internal/layers/data/models"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/jmoiron/sqlx"
)

var TrackNotFoundError = errors.New("Track is not found")

func NewTrackRepository(
	db *sqlx.DB,
) TrackRepository {
	return TrackRepository{
		Database: db,
	}
}

type TrackRepository struct {
	Database *sqlx.DB
}

func (r *TrackRepository) GetAllTracks() ([]entities.Track, error) {
	m := data_models.TracksModels{}

	err := r.Database.Select(&m, `
    SELECT * FROM tracks AND pending_import = 0
  `)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	tracks := m.ToTracks()

	err = r.LoadAlbumsInTracks(tracks)
	if err != nil {
		return nil, err
	}

	err = r.LoadArtistsInTracks(tracks)
	if err != nil {
		return nil, err
	}

	return tracks, nil
}

func (r *TrackRepository) GetAllTracksFromUser(userId int) ([]entities.Track, error) {
	m := data_models.TracksModels{}

	err := r.Database.Select(&m, `
    SELECT * FROM tracks WHERE user_id = ? AND pending_import = 0
  `, userId)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	tracks := m.ToTracks()

	err = r.LoadAlbumsInTracks(tracks)
	if err != nil {
		return nil, err
	}

	err = r.LoadArtistsInTracks(tracks)
	if err != nil {
		return nil, err
	}

	return tracks, nil
}

func (r *TrackRepository) GetAllTracksFromUserSince(
	userId int,
	since time.Time,
) ([]entities.Track, error) {
	m := data_models.TracksModels{}

	err := r.Database.Select(&m, `
    SELECT * FROM tracks WHERE user_id = ? AND pending_import = 0 AND (COALESCE(updated_at, created_at) >= ?)
  `, userId, since.UTC())
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	tracks := m.ToTracks()

	err = r.LoadAlbumsInTracks(tracks)
	if err != nil {
		return nil, err
	}

	err = r.LoadArtistsInTracks(tracks)
	if err != nil {
		return nil, err
	}

	return tracks, nil
}

func (r *TrackRepository) GetAllPendingImportTracksFromUser(userId int) ([]entities.Track, error) {
	m := data_models.TracksModels{}

	err := r.Database.Select(&m, `
    SELECT * FROM tracks WHERE user_id = ? AND pending_import = 1
  `, userId)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	tracks := m.ToTracks()

	err = r.LoadAlbumsInTracks(tracks)
	if err != nil {
		return nil, err
	}

	err = r.LoadArtistsInTracks(tracks)
	if err != nil {
		return nil, err
	}

	return tracks, nil
}

func (r *TrackRepository) GetTrack(
	id int,
) (*entities.Track, error) {
	m := data_models.TrackModel{}

	err := r.Database.Get(&m, `
    SELECT *
    FROM tracks
    WHERE id = ?
  `, id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, TrackNotFoundError
		}
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	track := m.ToTrack()

	err = r.LoadAlbumsInTrack(&track)
	if err != nil {
		return nil, err
	}

	err = r.LoadArtistsInTrack(&track)
	if err != nil {
		return nil, err
	}

	return &track, nil
}

func (r *TrackRepository) LoadAlbumsInTrack(track *entities.Track) error {
	m := data_models.AlbumModels{}

	err := r.Database.Select(&m, `
		SELECT albums.*
		FROM albums
		JOIN track_album ON albums.id = track_album.album_id
		WHERE track_album.track_id = ?
		ORDER BY track_album.album_pos ASC
  `, track.Id)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	track.Albums = m.ToAlbums()

	return nil
}

func (r *TrackRepository) LoadAlbumsInTracks(tracks []entities.Track) error {
	for i := range tracks {
		err := r.LoadAlbumsInTrack(&tracks[i])
		if err != nil {
			return nil
		}
	}

	return nil
}

func (r *TrackRepository) LoadArtistsInTrack(track *entities.Track) error {
	m := data_models.ArtistModels{}

	err := r.Database.Select(&m, `
		SELECT artists.*
		FROM artists
		JOIN track_artist ON artists.id = track_artist.artist_id
		WHERE track_artist.track_id = ?
		ORDER BY track_artist.artist_pos ASC
  `, track.Id)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	track.Artists = m.ToArtists()

	return nil
}

func (r *TrackRepository) LoadArtistsInTracks(tracks []entities.Track) error {
	for i := range tracks {
		err := r.LoadArtistsInTrack(&tracks[i])
		if err != nil {
			return nil
		}
	}

	return nil
}

func (r *TrackRepository) CreateTrack(track *entities.Track) error {
	m := data_models.TrackModel{}

	artists := "[]"

	if jsonData, err := json.Marshal(track.Metadata.Artists); err == nil {
		artists = string(jsonData)
	}

	albumArtists := "[]"

	if jsonData, err := json.Marshal(track.Metadata.AlbumArtists); err == nil {
		albumArtists = string(jsonData)
	}

	genres := "[]"

	if jsonData, err := json.Marshal(track.Metadata.Genres); err == nil {
		genres = string(jsonData)
	}

	artistsRoles := "[]"

	if jsonData, err := json.Marshal(data_models.TrackArtistRoleModelsFromEntities(track.Metadata.ArtistsRoles)); err == nil {
		artistsRoles = string(jsonData)
	}

	err := r.Database.Get(
		&m,
		`
    INSERT INTO tracks
      (
        user_id,

        title,
        duration,

        tags_format,
        file_type,

        path,
        file_signature,
        cover_signature,

        transcoding_low_signature,
        transcoding_medium_signature,
        transcoding_high_signature,

        metadata_album,

        metadata_track_number,
        metadata_total_tracks,

        metadata_disc_number,
        metadata_total_discs,

        metadata_date,
        metadata_year,

        metadata_genres,
        metadata_lyrics,
        metadata_comment,

        metadata_acoust_id,

        metadata_music_brainz_release_id,
        metadata_music_brainz_track_id,
        metadata_music_brainz_recording_id,

        metadata_artists,
        metadata_album_artists,
        metadata_artists_roles,

        metadata_composer,

        sample_rate,
        bit_rate,
        bits_per_raw_sample,

        pending_import,
				created_at
      )
    VALUES
      (
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
				STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
      )
    RETURNING *
  `,
		track.UserId,

		track.Title,
		track.Duration,

		track.TagsFormat,
		track.FileType,

		track.Path,
		track.FileSignature,
		track.CoverSignature,

		track.TranscodingLowSignature,
		track.TranscodingMediumSignature,
		track.TranscodingHighSignature,

		track.Metadata.Album,

		track.Metadata.TrackNumber,
		track.Metadata.TotalTracks,

		track.Metadata.DiscNumber,
		track.Metadata.TotalDiscs,

		track.Metadata.Date,
		track.Metadata.Year,

		genres,
		track.Metadata.Lyrics,
		track.Metadata.Comment,

		track.Metadata.AcoustID,

		track.Metadata.MusicBrainzReleaseId,
		track.Metadata.MusicBrainzTrackId,
		track.Metadata.MusicBrainzRecordingId,

		artists,
		albumArtists,
		artistsRoles,

		track.Metadata.Composer,

		track.SampleRate,
		track.BitRate,
		track.BitsPerRawSample,

		track.PendingImport,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	*track = m.ToTrack()

	err = r.LoadAlbumsInTrack(track)
	if err != nil {
		return err
	}

	err = r.LoadArtistsInTrack(track)
	if err != nil {
		return err
	}

	return nil
}

func (r *TrackRepository) UpdateTrack(track *entities.Track) error {
	m := data_models.TrackModel{}

	artists := "[]"

	if jsonData, err := json.Marshal(track.Metadata.Artists); err == nil {
		artists = string(jsonData)
	}

	albumArtists := "[]"

	if jsonData, err := json.Marshal(track.Metadata.AlbumArtists); err == nil {
		albumArtists = string(jsonData)
	}

	genres := "[]"

	if jsonData, err := json.Marshal(track.Metadata.Genres); err == nil {
		genres = string(jsonData)
	}

	artistsRoles := "[]"

	if jsonData, err := json.Marshal(data_models.TrackArtistRoleModelsFromEntities(track.Metadata.ArtistsRoles)); err == nil {
		artistsRoles = string(jsonData)
	}

	err := r.Database.Get(
		&m,
		`
    UPDATE tracks
    SET
        user_id = ?,

        title = ?,
        duration = ?,

        tags_format = ?,
        file_type = ?,

        path = ?,
        file_signature = ?,
        cover_signature = ?,

        transcoding_low_signature = ?,
        transcoding_medium_signature = ?,
        transcoding_high_signature = ?,

        metadata_album = ?,

        metadata_track_number = ?,
        metadata_total_tracks = ?,

        metadata_disc_number = ?,
        metadata_total_discs = ?,

        metadata_date = ?,
        metadata_year = ?,

        metadata_genres = ?,
        metadata_lyrics = ?,
        metadata_comment = ?,

        metadata_acoust_id = ?,

        metadata_music_brainz_release_id = ?,
        metadata_music_brainz_track_id = ?,
        metadata_music_brainz_recording_id = ?,

        metadata_artists = ?,
        metadata_album_artists = ?,
        metadata_artists_roles = ?,

        metadata_composer = ?,

        sample_rate = ?,
        bit_rate = ?,
        bits_per_raw_sample = ?,

        pending_import = ?,

        date_added = ?,

				updated_at = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE
      id = ?
    RETURNING *
  `,
		track.UserId,

		track.Title,
		track.Duration,

		track.TagsFormat,
		track.FileType,

		track.Path,
		track.FileSignature,
		track.CoverSignature,

		track.TranscodingLowSignature,
		track.TranscodingMediumSignature,
		track.TranscodingHighSignature,

		track.Metadata.Album,

		track.Metadata.TrackNumber,
		track.Metadata.TotalTracks,

		track.Metadata.DiscNumber,
		track.Metadata.TotalDiscs,

		track.Metadata.Date,
		track.Metadata.Year,

		genres,
		track.Metadata.Lyrics,
		track.Metadata.Comment,

		track.Metadata.AcoustID,

		track.Metadata.MusicBrainzReleaseId,
		track.Metadata.MusicBrainzTrackId,
		track.Metadata.MusicBrainzRecordingId,

		artists,
		albumArtists,
		artistsRoles,

		track.Metadata.Composer,

		track.SampleRate,
		track.BitRate,
		track.BitsPerRawSample,

		track.PendingImport,

		track.DateAdded,

		track.Id,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	*track = m.ToTrack()

	err = r.LoadAlbumsInTrack(track)
	if err != nil {
		return err
	}

	err = r.LoadArtistsInTrack(track)
	if err != nil {
		return err
	}

	return nil
}

func (r *TrackRepository) UpdateTrackPath(track *entities.Track) error {
	m := data_models.TrackModel{}

	err := r.Database.Get(
		&m,
		`
    UPDATE tracks
    SET
        path = ?
    WHERE
      id = ?
    RETURNING *
  `,
		track.Path,

		track.Id,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	*track = m.ToTrack()

	err = r.LoadAlbumsInTrack(track)
	if err != nil {
		return err
	}

	err = r.LoadArtistsInTrack(track)
	if err != nil {
		return err
	}

	return nil
}

func (r TrackRepository) SetTrackAlbums(track *entities.Track) error {
	if len(track.Albums) == 0 {
		_, err := r.Database.Exec(`
			DELETE FROM track_album
			WHERE track_id = ?
		`, track.Id)
		if err != nil {
			return err
		}

		return nil
	}

	tx, err := r.Database.Beginx()
	if err != nil {
		return err
	}

	albumIds := make([]int, len(track.Albums))

	for i, album := range track.Albums {
		albumIds[i] = album.Id
	}

	// Remove Extra

	delQuery, delArgs, err := sqlx.In(`
		DELETE FROM track_album
		WHERE track_id = ? AND album_id NOT IN (?)
	`, track.Id, albumIds)
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

	insertQuery := `INSERT OR IGNORE INTO track_album (track_id, album_id) VALUES `
	args := make([]any, 0, len(albumIds)*2)
	valuePlaceholders := ""

	for i, albumId := range albumIds {
		if i > 0 {
			valuePlaceholders += ", "
		}
		valuePlaceholders += "(?, ?)"
		args = append(args, track.Id, albumId)
	}

	insertQuery += valuePlaceholders

	_, err = tx.Exec(insertQuery, args...)
	if err != nil {
		_ = tx.Rollback()
		return err
	}

	// Set Order

	for i, albumId := range albumIds {
		_, err = tx.Exec(
			"UPDATE track_album SET album_pos = ? WHERE track_id = ? AND album_id = ?",
			i,
			track.Id,
			albumId,
		)
		if err != nil {
			_ = tx.Rollback()
			return err
		}
	}

	// Update

	_, err = tx.Exec(
		"UPDATE tracks SET updated_at = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW') WHERE id = ?",
		track.Id,
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

func (r TrackRepository) SetTrackArtists(track *entities.Track) error {
	if len(track.Artists) == 0 {
		_, err := r.Database.Exec(`
			DELETE FROM track_artist
			WHERE track_id = ?
		`, track.Id)
		if err != nil {
			return err
		}

		return nil
	}

	tx, err := r.Database.Beginx()
	if err != nil {
		return err
	}

	artistIds := make([]int, len(track.Artists))

	for i, artist := range track.Artists {
		artistIds[i] = artist.Id
	}

	// Remove Extra

	delQuery, delArgs, err := sqlx.In(`
		DELETE FROM track_artist
		WHERE track_id = ? AND artist_id NOT IN (?)
	`, track.Id, artistIds)
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

	insertQuery := `INSERT OR IGNORE INTO track_artist (track_id, artist_id) VALUES `
	args := make([]any, 0, len(artistIds)*2)
	valuePlaceholders := ""

	for i, artistId := range artistIds {
		if i > 0 {
			valuePlaceholders += ", "
		}
		valuePlaceholders += "(?, ?)"
		args = append(args, track.Id, artistId)
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
			"UPDATE track_artist SET artist_pos = ? WHERE track_id = ? AND artist_id = ?",
			i,
			track.Id,
			artistId,
		)
		if err != nil {
			_ = tx.Rollback()
			return err
		}
	}

	// Update

	_, err = tx.Exec(
		"UPDATE tracks SET updated_at = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW') WHERE id = ?",
		track.Id,
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

func (r *TrackRepository) DeleteTrack(track *entities.Track) error {
	m := data_models.TrackModel{}

	tx, err := r.Database.Beginx()
	if err != nil {
		return err
	}

	err = tx.Get(&m, `
    DELETE FROM
      tracks
    WHERE 
      id = ?
    RETURNING *
  `,
		track.Id,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		_ = tx.Rollback()
		return err
	}

	_, err = tx.Exec("INSERT INTO deleted_tracks (id) VALUES (?)", track.Id)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		_ = tx.Rollback()
		return err
	}

	if err := tx.Commit(); err != nil {
		return err
	}

	*track = m.ToTrack()

	err = r.LoadAlbumsInTrack(track)
	if err != nil {
		return err
	}

	err = r.LoadArtistsInTrack(track)
	if err != nil {
		return err
	}

	return nil
}

func (r *TrackRepository) GetAllDeletedTracksSince(since time.Time) ([]int, error) {
	rows, err := r.Database.Query(`
    SELECT id FROM deleted_tracks WHERE deleted_at >= datetime(?)
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
