package repository

import "gungun974.com/melodink-server/internal/layers/domain/entities"

type TrackRepository interface {
	GetAllTracks() ([]entities.Track, error)

	CreateTrack(*entities.Track) error

	UpdateTrack(*entities.Track) error
}
