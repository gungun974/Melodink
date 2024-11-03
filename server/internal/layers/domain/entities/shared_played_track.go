package entities

import (
	"time"
)

type SharedPlayedTrack struct {
	Id int

	UserId   int
	DeviceId string

	TrackId int

	StartAt  time.Time
	FinishAt time.Time

	BeginAt int
	EndedAt int

	Shuffle bool

	TrackEnded bool

	SharedAt time.Time
}
