package track_usecase

import (
	presenter "gungun974.com/melodink-server/internal/layers/domain/presenters"
	processor "gungun974.com/melodink-server/internal/layers/domain/processors"
	"gungun974.com/melodink-server/internal/layers/domain/repository"
	"gungun974.com/melodink-server/internal/layers/domain/storage"
)

type TrackUsecase struct {
	trackRepository repository.TrackRepository
	trackStorage    storage.TrackStorage
	audioProcessor  processor.AudioProcessor
	trackPresenter  presenter.TrackPresenter
}

func NewTrackUsecase(
	trackRepository repository.TrackRepository,
	trackStorage storage.TrackStorage,
	audioProcessor processor.AudioProcessor,
	trackPresenter presenter.TrackPresenter,
) TrackUsecase {
	return TrackUsecase{
		trackRepository,
		trackStorage,
		audioProcessor,
		trackPresenter,
	}
}
