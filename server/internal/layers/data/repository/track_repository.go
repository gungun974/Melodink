package repository

import (
	"database/sql"
	"encoding/json"
	"errors"

	data_models "github.com/gungun974/Melodink/server/internal/layers/data/models"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/jmoiron/sqlx"
)

var TrackNotFoundError = errors.New("Track is not found")

func NewTrackRepository(db *sqlx.DB) TrackRepository {
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

	return m.ToTracks(), nil
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

	return m.ToTracks(), nil
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

	return m.ToTracks(), nil
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

	return &track, nil
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

        pending_import
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
        ? 
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

        date_added = ?
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

	return nil
}

func (r *TrackRepository) DeleteTrack(track *entities.Track) error {
	m := data_models.TrackModel{}

	err := r.Database.Get(&m, `
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
		return err
	}

	*track = m.ToTrack()

	return nil
}
