package data_models

import (
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type TrackScoresModels []TrackScoreModel

func (s TrackScoresModels) ToTrackScores() []entities.TrackScore {
	e := make([]entities.TrackScore, 0, len(s))

	for _, m := range s {
		e = append(e, m.ToTrackScore())
	}

	return e
}

type TrackScoreModel struct {
	TrackId int `db:"track_id"`
	UserId  int `db:"user_id"`

	Score float64 `db:"score"`
}

func (m *TrackScoreModel) ToTrackScore() entities.TrackScore {
	return entities.TrackScore{
		TrackId: m.TrackId,

		UserId: m.UserId,

		Score: m.Score,
	}
}
