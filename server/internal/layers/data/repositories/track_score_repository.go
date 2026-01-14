package repositories

import (
	data_models "github.com/gungun974/Melodink/server/internal/layers/data/models"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/jmoiron/sqlx"
)

func (r *TrackRepository) SetUserTrackScore(
	track entities.Track,
	userId int,
	score float64,
) (entities.TrackScore, error) {
	m := data_models.TrackScoreModel{}

	err := r.Database.Get(
		&m,
		`
    INSERT OR REPLACE INTO track_score
      (
        track_id,
        user_id,
        score
      )
    VALUES
      (
        ?,
        ?,
        ?
      )
    RETURNING *
  `,
		track.Id,
		userId,
		score,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return entities.TrackScore{}, err
	}

	_, err = r.Database.Exec(
		"UPDATE tracks SET updated_at = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW') WHERE id = ?",
		track.Id,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
	}

	return m.ToTrackScore(), nil
}

func (r *TrackRepository) GetAllScoresByTrack(trackId int) ([]entities.TrackScore, error) {
	m := data_models.TrackScoresModels{}

	err := r.Database.Select(&m, `
    SELECT * FROM track_score WHERE track_id = ?
  `, trackId)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	return m.ToTrackScores(), nil
}

func (r *TrackRepository) LoadAllScoresWithTracks(tracks []entities.Track) error {
	if len(tracks) <= 0 {
		return nil
	}

	tracksIds := make([]int, len(tracks))

	for i, t := range tracks {
		tracksIds[i] = t.Id
	}

	m := data_models.TrackScoresModels{}

	query, args, err := sqlx.In(`
    SELECT *
    FROM track_score
    WHERE track_id IN (?)
  `, tracksIds)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	query = r.Database.Rebind(query)

	err = r.Database.Select(&m, query, args...)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	for i := range tracks {
		tracks[i].Scores = make([]entities.TrackScore, 0)

		for _, r := range m {
			if tracks[i].Id == r.TrackId {
				tracks[i].Scores = append(tracks[i].Scores, r.ToTrackScore())
			}
		}
	}

	return nil
}
