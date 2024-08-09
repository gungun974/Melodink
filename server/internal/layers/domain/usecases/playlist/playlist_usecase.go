package playlist_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenter"
)

type PlaylistUsecase struct {
	playlistRepository repository.PlaylistRepository
	trackRepository    repository.TrackRepository
	playlistPresenter  presenter.PlaylistPresenter
}

func NewPlaylistUsecase(
	playlistRepository repository.PlaylistRepository,
	trackRepository repository.TrackRepository,
	playlistPresenter presenter.PlaylistPresenter,
) PlaylistUsecase {
	return PlaylistUsecase{
		playlistRepository,
		trackRepository,
		playlistPresenter,
	}
}
