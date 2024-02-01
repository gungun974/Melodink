package repository

import (
	"errors"

	"gungun974.com/melodink-server/internal/layers/domain/entities"
)

var TrackNotFoundError = errors.New("Track is not found")

type TrackRepository interface {
	GetAllTracks() ([]entities.Track, error)

	GetTrack(id int) (*entities.Track, error)

	CreateTrack(*entities.Track) error

	UpdateTrack(*entities.Track) error
}
