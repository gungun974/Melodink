package sync_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/data/storage"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenter"
)

type SyncUsecase struct {
	trackRepository             repository.TrackRepository
	albumRepository             repository.AlbumRepository
	artistRepository            repository.ArtistRepository
	playlistRepository          repository.PlaylistRepository
	sharedPlayedTrackRepository repository.SharedPlayedTrackRepository

	coverStorage storage.CoverStorage

	syncPresenter presenter.SyncPresenter
}

func NewSyncUsecase(
	trackRepository repository.TrackRepository,
	albumRepository repository.AlbumRepository,
	artistRepository repository.ArtistRepository,
	playlistRepository repository.PlaylistRepository,
	sharedPlayedTrackRepository repository.SharedPlayedTrackRepository,
	coverStorage storage.CoverStorage,
	syncPresenter presenter.SyncPresenter,
) SyncUsecase {
	return SyncUsecase{
		trackRepository,
		albumRepository,
		artistRepository,
		playlistRepository,
		sharedPlayedTrackRepository,
		coverStorage,
		syncPresenter,
	}
}
