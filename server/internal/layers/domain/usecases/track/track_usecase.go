package track_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/data/scanner"
	"github.com/gungun974/Melodink/server/internal/layers/data/storage"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenter"
)

type TrackUsecase struct {
	trackRepository    repository.TrackRepository
	trackStorage       storage.TrackStorage
	acoustIdScanner    scanner.AcoustIdScanner
	musicBrainzScanner scanner.MusicBrainzScanner
	trackPresenter     presenter.TrackPresenter
}

func NewTrackUsecase(
	trackRepository repository.TrackRepository,
	trackStorage storage.TrackStorage,
	acoustIdScanner scanner.AcoustIdScanner,
	musicBrainzScanner scanner.MusicBrainzScanner,
	trackPresenter presenter.TrackPresenter,
) TrackUsecase {
	return TrackUsecase{
		trackRepository,
		trackStorage,
		acoustIdScanner,
		musicBrainzScanner,
		trackPresenter,
	}
}
