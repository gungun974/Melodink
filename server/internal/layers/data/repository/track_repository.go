package repository

import (
	"database/sql"
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
    SELECT * FROM tracks
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
    SELECT * FROM tracks WHERE user_id = ?
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

        metadata_genre,
        metadata_lyrics,
        metadata_comment,

        metadata_acoust_id,
        metadata_acoust_id_fingerprint,

        metadata_artist,
        metadata_album_artist,
        metadata_composer,

        metadata_copyright
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

		track.Metadata.Genre,
		track.Metadata.Lyrics,
		track.Metadata.Comment,

		track.Metadata.AcoustID,
		track.Metadata.AcoustIDFingerprint,

		track.Metadata.Artist,
		track.Metadata.AlbumArtist,
		track.Metadata.Composer,

		track.Metadata.Copyright,
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

        metadata_genre = ?,
        metadata_lyrics = ?,
        metadata_comment = ?,

        metadata_acoust_id = ?,
        metadata_acoust_id_fingerprint = ?,

        metadata_artist = ?,
        metadata_album_artist = ?,
        metadata_composer = ?,

        metadata_copyright = ? 
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

		track.Metadata.Genre,
		track.Metadata.Lyrics,
		track.Metadata.Comment,

		track.Metadata.AcoustID,
		track.Metadata.AcoustIDFingerprint,

		track.Metadata.Artist,
		track.Metadata.AlbumArtist,
		track.Metadata.Composer,

		track.Metadata.Copyright,

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
