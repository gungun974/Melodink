package playlist_usecase

import (
	presenter "gungun974.com/melodink-server/internal/layers/domain/presenters"
	"gungun974.com/melodink-server/internal/layers/domain/repository"
)

type PlaylistUsecase struct {
	playlistRepository repository.PlaylistRepository
	playlistPresenter  presenter.PlaylistPresenter
}

func NewPlaylistUsecase(
	playlistRepository repository.PlaylistRepository,
	playlistPresenter presenter.PlaylistPresenter,
) PlaylistUsecase {
	return PlaylistUsecase{
		playlistRepository,
		playlistPresenter,
	}
}
