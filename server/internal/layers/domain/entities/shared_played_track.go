package entities

import (
	"time"
)

type SharedPlayedTrack struct {
	Id               int
	InternalDeviceId int

	UserId   int
	DeviceId string

	TrackId int

	StartAt  time.Time
	FinishAt time.Time

	BeginAt int
	EndedAt int

	Shuffle bool

	TrackEnded    bool
	TrackDuration int

	SharedAt time.Time
}
