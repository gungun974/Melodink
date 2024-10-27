package playlist_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/data/storage"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenter"
)

type PlaylistUsecase struct {
	playlistRepository repository.PlaylistRepository
	trackRepository    repository.TrackRepository
	coverStorage       storage.CoverStorage
	playlistPresenter  presenter.PlaylistPresenter
}

func NewPlaylistUsecase(
	playlistRepository repository.PlaylistRepository,
	trackRepository repository.TrackRepository,
	coverStorage storage.CoverStorage,
	playlistPresenter presenter.PlaylistPresenter,
) PlaylistUsecase {
	return PlaylistUsecase{
		playlistRepository,
		trackRepository,
		coverStorage,
		playlistPresenter,
	}
}
