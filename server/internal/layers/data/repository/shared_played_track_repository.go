package repository

import (
	"time"

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

func (r *SharedPlayedTrackRepository) GetAllSharedPlayedTracksFromUser(
	userId int,
) ([]entities.SharedPlayedTrack, error) {
	m := data_models.SharedPlayedTrackModels{}

	err := r.Database.Select(&m, `
    SELECT * FROM shared_played_tracks WHERE user_id = ?
  `, userId)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	return m.ToSharedPlayedTracks(), nil
}

func (r *SharedPlayedTrackRepository) GetAllSharedPlayedTracksFromUserSince(
	userId int,
	since time.Time,
) ([]entities.SharedPlayedTrack, error) {
	m := data_models.SharedPlayedTrackModels{}

	err := r.Database.Select(&m, `
    SELECT * FROM shared_played_tracks WHERE user_id = ? AND (COALESCE(updated_at, created_at) >= ?)
  `, userId, since.UTC())
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
      	updated_at = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
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
        track_duration,
				updated_at
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
				STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
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

func (r *SharedPlayedTrackRepository) DeleteSharedPlayedTrack(playedTrack *entities.SharedPlayedTrack) error {
	m := data_models.SharedPlayedTrackModel{}

	tx, err := r.Database.Beginx()
	if err != nil {
		return err
	}

	err = tx.Get(&m, `
    DELETE FROM
      shared_played_tracks
    WHERE 
      id = ?
    RETURNING *
  `,
		playedTrack.Id,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		_ = tx.Rollback()
		return err
	}

	_, err = tx.Exec("INSERT INTO deleted_shared_played_tracks (id) VALUES (?)", playedTrack.Id)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		_ = tx.Rollback()
		return err
	}

	if err := tx.Commit(); err != nil {
		return err
	}

	*playedTrack = m.ToSharedPlayedTrack()

	return nil
}

func (r *SharedPlayedTrackRepository) GetAllDeletedSharedPlayedTracksSince(since time.Time) ([]int, error) {
	rows, err := r.Database.Query(`
    SELECT id FROM deleted_shared_played_tracks WHERE deleted_at >= ?
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
