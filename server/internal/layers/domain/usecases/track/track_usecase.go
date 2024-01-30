package track_usecase

import (
	"gungun974.com/melodink-server/internal/layers/domain/repository"
	"gungun974.com/melodink-server/internal/layers/domain/storage"
)

type TrackUsecase struct {
	trackRepository repository.TrackRepository
	trackStorage    storage.TrackStorage
}

func NewTrackUsecase(
	trackRepository repository.TrackRepository,
	trackStorage storage.TrackStorage,
) TrackUsecase {
	return TrackUsecase{
		trackRepository,
		trackStorage,
	}
}
