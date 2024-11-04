package data_models

import (
	"time"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type SharedPlayedTrackModels []SharedPlayedTrackModel

func (s SharedPlayedTrackModels) ToSharedPlayedTracks() []entities.SharedPlayedTrack {
	e := make([]entities.SharedPlayedTrack, 0, len(s))

	for _, m := range s {
		e = append(e, m.ToSharedPlayedTrack())
	}

	return e
}

type SharedPlayedTrackModel struct {
	Id               int `db:"id"`
	InternalDeviceId int `db:"internal_device_id"`

	UserId   int    `db:"user_id"`
	DeviceId string `db:"device_id"`

	TrackId int `db:"track_id"`

	StartAt  time.Time `db:"start_at"`
	FinishAt time.Time `db:"finish_at"`

	BeginAt int `db:"begin_at"`
	EndedAt int `db:"ended_at"`

	Shuffle    bool `db:"shuffle"`
	TrackEnded bool `db:"track_ended"`

	SharedAt time.Time `db:"shared_at"`
}

func (m *SharedPlayedTrackModel) ToSharedPlayedTrack() entities.SharedPlayedTrack {
	return entities.SharedPlayedTrack{
		Id:               m.Id,
		InternalDeviceId: m.InternalDeviceId,

		UserId:   m.UserId,
		DeviceId: m.DeviceId,

		TrackId: m.TrackId,

		StartAt:  m.StartAt,
		FinishAt: m.FinishAt,

		BeginAt: m.BeginAt,
		EndedAt: m.EndedAt,

		Shuffle:    m.Shuffle,
		TrackEnded: m.TrackEnded,

		SharedAt: m.SharedAt,
	}
}
