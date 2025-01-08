package view_models

import (
	"time"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type SharedPlayedTrackViewModel struct {
	Id               int `json:"id"`
	InternalDeviceId int `json:"internal_device_id"`

	UserId   int    `json:"user_id"`
	DeviceId string `json:"device_id"`

	TrackId int `json:"track_id"`

	StartAt  string `json:"start_at"`
	FinishAt string `json:"finish_at"`

	BeginAt int `json:"begin_at"`
	EndedAt int `json:"ended_at"`

	Shuffle bool `json:"shuffle"`

	TrackEnded bool `json:"track_ended"`

	TrackDuration int `json:"track_duration"`

	SharedAt string `json:"shared_at"`
}

func ConvertToSharedPlayedTrackViewModel(
	playedTrack entities.SharedPlayedTrack,
) SharedPlayedTrackViewModel {
	return SharedPlayedTrackViewModel{
		Id:               playedTrack.Id,
		InternalDeviceId: playedTrack.InternalDeviceId,

		UserId:   playedTrack.UserId,
		DeviceId: playedTrack.DeviceId,

		TrackId: playedTrack.TrackId,

		StartAt:  playedTrack.StartAt.UTC().Format(time.RFC3339),
		FinishAt: playedTrack.FinishAt.UTC().Format(time.RFC3339),

		BeginAt: playedTrack.BeginAt,
		EndedAt: playedTrack.EndedAt,

		Shuffle: playedTrack.Shuffle,

		TrackEnded: playedTrack.TrackEnded,

		TrackDuration: playedTrack.TrackDuration,

		SharedAt: playedTrack.SharedAt.UTC().Format(time.RFC3339),
	}
}
