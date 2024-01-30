package track_usecase

import (
	presenter "gungun974.com/melodink-server/internal/layers/domain/presenters"
	"gungun974.com/melodink-server/internal/layers/domain/repository"
	"gungun974.com/melodink-server/internal/layers/domain/storage"
)

type TrackUsecase struct {
	trackRepository repository.TrackRepository
	trackStorage    storage.TrackStorage
	trackPresenter  presenter.TrackPresenter
}

func NewTrackUsecase(
	trackRepository repository.TrackRepository,
	trackStorage storage.TrackStorage,
	trackPresenter presenter.TrackPresenter,
) TrackUsecase {
	return TrackUsecase{
		trackRepository,
		trackStorage,
		trackPresenter,
	}
}
