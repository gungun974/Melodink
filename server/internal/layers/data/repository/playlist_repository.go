package repository

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

var PlaylistNotFoundError = errors.New("Playlist is not found")

func NewPlaylistRepository(db *sqlx.DB, trackRepository TrackRepository) PlaylistRepository {
	return PlaylistRepository{
		Database:        db,
		trackRepository: trackRepository,
	}
}

type PlaylistRepository struct {
	Database        *sqlx.DB
	trackRepository TrackRepository
}

func (r *PlaylistRepository) GetAllPlaylists() ([]entities.Playlist, error) {
	m := data_models.PlaylistsModels{}

	err := r.Database.Select(&m, `
    SELECT * FROM playlists
  `)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	playlists := m.ToPlaylists()

	err = r.loadPlaylistsTracks(playlists, m)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	return playlists, nil
}

func (r *PlaylistRepository) GetAllPlaylistsFromUser(userId int) ([]entities.Playlist, error) {
	m := data_models.PlaylistsModels{}

	err := r.Database.Select(&m, `
    SELECT * FROM playlists WHERE user_id = ?
  `, userId)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	playlists := m.ToPlaylists()

	err = r.loadPlaylistsTracks(playlists, m)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	return playlists, nil
}

func (r *PlaylistRepository) GetAllPlaylistsFromUserSince(
	userId int,
	since time.Time,
) ([]entities.Playlist, error) {
	m := data_models.PlaylistsModels{}

	err := r.Database.Select(&m, `
    SELECT * FROM playlists WHERE user_id = ? AND (COALESCE(updated_at, created_at) >= ?)
  `, userId, since.UTC())
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	playlists := m.ToPlaylists()

	err = r.loadPlaylistsTracks(playlists, m)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	return playlists, nil
}

func (r *PlaylistRepository) GetPlaylist(
	id int,
) (*entities.Playlist, error) {
	m := data_models.PlaylistModel{}

	err := r.Database.Get(&m, `
    SELECT *
    FROM playlists
    WHERE id = ?
  `, id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, PlaylistNotFoundError
		}
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	playlist := m.ToPlaylist()

	err = r.loadPlaylistTracks(&playlist, m)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	return &playlist, nil
}

func (r *PlaylistRepository) CreatePlaylist(playlist *entities.Playlist) error {
	m := data_models.PlaylistModel{}

	err := r.Database.Get(
		&m,
		`
    INSERT INTO playlists
      (
        user_id,

        name,
        description,

        track_ids,
        created_at 
      )
    VALUES
      (
        ?,

        ?,
        ?,

        '[]',
				STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
      )
    RETURNING *
  `,
		playlist.UserId,

		playlist.Name,
		playlist.Description,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	*playlist = m.ToPlaylist()

	return nil
}

func (r *PlaylistRepository) UpdatePlaylist(playlist *entities.Playlist) error {
	m := data_models.PlaylistModel{}

	err := r.Database.Get(
		&m,
		`
    UPDATE playlists
    SET
        user_id = ?,

        name = ?,
        description = ?,

        updated_at = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE
      id = ?
    RETURNING *
  `,
		playlist.UserId,

		playlist.Name,
		playlist.Description,

		playlist.Id,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	*playlist = m.ToPlaylist()

	err = r.loadPlaylistTracks(playlist, m)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	return nil
}

func (r *PlaylistRepository) SetPlaylistTracks(playlist *entities.Playlist) error {
	m := data_models.PlaylistModel{}

	trackIds := make([]int, len(playlist.Tracks))

	for i, track := range playlist.Tracks {
		trackIds[i] = track.Id
	}

	encodedTrackIds, err := json.Marshal(trackIds)
	if err != nil {
		logger.DatabaseLogger.Errorf("Failed to encode tracksIds JSON into the database : %v", err)
		return err
	}

	err = r.Database.Get(
		&m,
		`
    UPDATE playlists
    SET
        track_ids = ?,
        updated_at = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE
      id = ?
    RETURNING *
  `,
		encodedTrackIds,
		playlist.Id,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	*playlist = m.ToPlaylist()

	err = r.loadPlaylistTracks(playlist, m)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	return nil
}

func (r *PlaylistRepository) loadPlaylistsTracks(
	playlists []entities.Playlist,
	m data_models.PlaylistsModels,
) error {
	for i := range m {
		err := r.loadPlaylistTracks(&playlists[i], m[i])
		if err != nil {
			return err
		}
	}

	return nil
}

func (r *PlaylistRepository) loadPlaylistTracks(
	playlist *entities.Playlist,
	m data_models.PlaylistModel,
) error {
	var trackIds []int

	err := json.Unmarshal([]byte(m.TrackIds), &trackIds)
	if err != nil {
		logger.DatabaseLogger.Errorf("Failed to decode track_ids json of %v : %v", playlist, err)
		return err
	}

	tracks := make([]entities.Track, 0, len(trackIds))

	for _, trackId := range trackIds {
		track, err := r.trackRepository.GetTrack(trackId)
		if err != nil {
			if errors.Is(err, TrackNotFoundError) {
				continue
			}
			return err
		}

		tracks = append(tracks, *track)
	}

	playlist.Tracks = tracks

	return nil
}

func (r *PlaylistRepository) DeletePlaylist(playlist *entities.Playlist) error {
	m := data_models.PlaylistModel{}

	tx, err := r.Database.Beginx()
	if err != nil {
		return err
	}

	err = tx.Get(&m, `
    DELETE FROM
      playlists
    WHERE 
      id = ?
    RETURNING *
  `,
		playlist.Id,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		_ = tx.Rollback()
		return err
	}

	_, err = tx.Exec("INSERT INTO deleted_playlists (id) VALUES (?)", playlist.Id)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		_ = tx.Rollback()
		return err
	}

	if err := tx.Commit(); err != nil {
		return err
	}

	*playlist = m.ToPlaylist()

	err = r.loadPlaylistTracks(playlist, m)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	return nil
}

func (r *PlaylistRepository) GetAllDeletedPlaylistsSince(since time.Time) ([]int, error) {
	rows, err := r.Database.Query(`
    SELECT id FROM deleted_playlists WHERE deleted_at >= datetime(?)
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
