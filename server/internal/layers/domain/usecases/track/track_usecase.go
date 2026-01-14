package track_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/processors"
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/data/scanners"
	"github.com/gungun974/Melodink/server/internal/layers/data/storages"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenters"
)

type TrackUsecase struct {
	trackRepository    repositories.TrackRepository
	albumRepository    repositories.AlbumRepository
	artistRepository   repositories.ArtistRepository
	trackStorage       storages.TrackStorage
	coverStorage       storages.CoverStorage
	transcodeStorage   storages.TranscodeStorage
	acoustIdScanner    scanners.AcoustIdScanner
	musicBrainzScanner scanners.MusicBrainzScanner
	transcodeProcessor processors.TranscodeProcessor
	trackPresenter     presenters.TrackPresenter
}

func NewTrackUsecase(
	trackRepository repositories.TrackRepository,
	albumRepository repositories.AlbumRepository,
	artistRepository repositories.ArtistRepository,
	trackStorage storages.TrackStorage,
	coverStorage storages.CoverStorage,
	transcodeStorage storages.TranscodeStorage,
	acoustIdScanner scanners.AcoustIdScanner,
	musicBrainzScanner scanners.MusicBrainzScanner,
	transcodeProcessor processors.TranscodeProcessor,
	trackPresenter presenters.TrackPresenter,
) TrackUsecase {
	return TrackUsecase{
		trackRepository,
		albumRepository,
		artistRepository,
		trackStorage,
		coverStorage,
		transcodeStorage,
		acoustIdScanner,
		musicBrainzScanner,
		transcodeProcessor,
		trackPresenter,
	}
}
