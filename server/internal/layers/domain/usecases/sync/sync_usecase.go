package sync_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/data/storages"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenters"
)

type SyncUsecase struct {
	trackRepository             repositories.TrackRepository
	albumRepository             repositories.AlbumRepository
	artistRepository            repositories.ArtistRepository
	playlistRepository          repositories.PlaylistRepository
	sharedPlayedTrackRepository repositories.SharedPlayedTrackRepository

	coverStorage storages.CoverStorage

	syncPresenter presenters.SyncPresenter
}

func NewSyncUsecase(
	trackRepository repositories.TrackRepository,
	albumRepository repositories.AlbumRepository,
	artistRepository repositories.ArtistRepository,
	playlistRepository repositories.PlaylistRepository,
	sharedPlayedTrackRepository repositories.SharedPlayedTrackRepository,
	coverStorage storages.CoverStorage,
	syncPresenter presenters.SyncPresenter,
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
