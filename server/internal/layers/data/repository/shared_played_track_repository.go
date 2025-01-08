package repository

import (
	data_models "github.com/gungun974/Melodink/server/internal/layers/data/models"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/jmoiron/sqlx"
)

func NewSharedPlayedTrackRepository(db *sqlx.DB) SharedPlayedTrackRepository {
	return SharedPlayedTrackRepository{
		Database: db,
	}
}

type SharedPlayedTrackRepository struct {
	Database *sqlx.DB
}

func (r *SharedPlayedTrackRepository) GetSharedPlayedTracksFromIdToLast(
	userId int,
	fromId int,
) ([]entities.SharedPlayedTrack, error) {
	m := data_models.SharedPlayedTrackModels{}

	err := r.Database.Select(&m, `
    SELECT * FROM shared_played_tracks WHERE user_id = ? and id > ?
  `, userId, fromId)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	return m.ToSharedPlayedTracks(), nil
}

func (r *SharedPlayedTrackRepository) AddSharedPlayedTrack(
	playedTrack *entities.SharedPlayedTrack,
) error {
	m := data_models.SharedPlayedTrackModel{}

	err := r.Database.Get(
		&m,
		`
    UPDATE shared_played_tracks
    SET 
        user_id = ?,
        track_id = ?,
        start_at = ?,
        finish_at = ?,
        begin_at = ?,
        ended_at = ?,
        shuffle = ?,
        track_ended = ?
        track_duration = ?
    WHERE internal_device_id = ? AND device_id = ?
    RETURNING *;
  `,
		playedTrack.UserId,

		playedTrack.TrackId,

		playedTrack.StartAt,
		playedTrack.FinishAt,

		playedTrack.BeginAt,
		playedTrack.EndedAt,

		playedTrack.Shuffle,
		playedTrack.TrackEnded,
		playedTrack.TrackDuration,

		playedTrack.InternalDeviceId,
		playedTrack.DeviceId,
	)
	if err == nil {
		*playedTrack = m.ToSharedPlayedTrack()

		return nil
	}

	err = r.Database.Get(
		&m,
		`
    INSERT OR REPLACE INTO shared_played_tracks
      (
        internal_device_id,
        user_id,
        device_id,

        track_id,

        start_at,
        finish_at,

        begin_at,
        ended_at,

        shuffle,
        track_ended,
        track_duration
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
        ?
      )
    RETURNING *
  `,
		playedTrack.InternalDeviceId,

		playedTrack.UserId,
		playedTrack.DeviceId,

		playedTrack.TrackId,

		playedTrack.StartAt,
		playedTrack.FinishAt,

		playedTrack.BeginAt,
		playedTrack.EndedAt,

		playedTrack.Shuffle,
		playedTrack.TrackEnded,
		playedTrack.TrackDuration,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	*playedTrack = m.ToSharedPlayedTrack()

	return nil
}
