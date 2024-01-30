package repository_impl

import (
	"github.com/jmoiron/sqlx"
	data_models "gungun974.com/melodink-server/internal/layers/data/models"
	"gungun974.com/melodink-server/internal/layers/domain/entities"
	"gungun974.com/melodink-server/internal/layers/domain/repository"
	"gungun974.com/melodink-server/internal/logger"
)

func NewTrackRepository(db *sqlx.DB) repository.TrackRepository {
	return &TrackRepositoryImpl{
		Database: db,
	}
}

type TrackRepositoryImpl struct {
	Database *sqlx.DB
}

func (r *TrackRepositoryImpl) GetAllTracks() ([]entities.Track, error) {
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

func (r *TrackRepositoryImpl) CreateTrack(track *entities.Track) error {
	m := data_models.TrackModel{}

	err := r.Database.Get(
		&m,
		`
    INSERT INTO tracks
      (
        title,
        album,
        duration,

        tags_format,
        file_type,

        path,
        file_signature,

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
        ? 
      )
    RETURNING *
  `,
		track.Title,
		track.Album,
		track.Duration,

		track.TagsFormat,
		track.FileType,

		track.Path,
		track.FileSignature,

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

func (r *TrackRepositoryImpl) UpdateTrack(track *entities.Track) error {
	m := data_models.TrackModel{}

	err := r.Database.Get(
		&m,
		`
    UPDATE tracks
    SET
        title = ?,
        album = ?,
        duration = ?,

        tags_format = ?,
        file_type = ?,

        path = ?,
        file_signature = ?,

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
		track.Title,
		track.Album,
		track.Duration,

		track.TagsFormat,
		track.FileType,

		track.Path,
		track.FileSignature,

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
