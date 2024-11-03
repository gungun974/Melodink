package shared_played_track_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenter"
)

type SharedPlayedTrackUsecase struct {
	sharedPlayedTrackRepository repository.SharedPlayedTrackRepository
	sharedPlayedTrackPresenter  presenter.SharedPlayedTrackPresenter
}

func NewSharedPlayedTrackUsecase(
	sharedPlayedTrackRepository repository.SharedPlayedTrackRepository,
	sharedPlayedTrackPresenter presenter.SharedPlayedTrackPresenter,
) SharedPlayedTrackUsecase {
	return SharedPlayedTrackUsecase{
		sharedPlayedTrackRepository,
		sharedPlayedTrackPresenter,
	}
}
