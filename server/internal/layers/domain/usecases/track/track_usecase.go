package track_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/processor"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/data/scanner"
	"github.com/gungun974/Melodink/server/internal/layers/data/storage"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenter"
)

type TrackUsecase struct {
	trackRepository    repository.TrackRepository
	trackStorage       storage.TrackStorage
	coverStorage       storage.CoverStorage
	acoustIdScanner    scanner.AcoustIdScanner
	musicBrainzScanner scanner.MusicBrainzScanner
	hlsProcessor       processor.HlsProcessor
	trackPresenter     presenter.TrackPresenter
}

func NewTrackUsecase(
	trackRepository repository.TrackRepository,
	trackStorage storage.TrackStorage,
	coverStorage storage.CoverStorage,
	acoustIdScanner scanner.AcoustIdScanner,
	musicBrainzScanner scanner.MusicBrainzScanner,
	hlsProcessor processor.HlsProcessor,
	trackPresenter presenter.TrackPresenter,
) TrackUsecase {
	return TrackUsecase{
		trackRepository,
		trackStorage,
		coverStorage,
		acoustIdScanner,
		musicBrainzScanner,
		hlsProcessor,
		trackPresenter,
	}
}
