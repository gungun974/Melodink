package shared_played_track_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenters"
)

type SharedPlayedTrackUsecase struct {
	sharedPlayedTrackRepository repositories.SharedPlayedTrackRepository
	sharedPlayedTrackPresenter  presenters.SharedPlayedTrackPresenter
}

func NewSharedPlayedTrackUsecase(
	sharedPlayedTrackRepository repositories.SharedPlayedTrackRepository,
	sharedPlayedTrackPresenter presenters.SharedPlayedTrackPresenter,
) SharedPlayedTrackUsecase {
	return SharedPlayedTrackUsecase{
		sharedPlayedTrackRepository,
		sharedPlayedTrackPresenter,
	}
}
