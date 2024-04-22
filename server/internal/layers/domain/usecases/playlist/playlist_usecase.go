package playlist_usecase

import (
	presenter "gungun974.com/melodink-server/internal/layers/domain/presenters"
	"gungun974.com/melodink-server/internal/layers/domain/repository"
)

type PlaylistUsecase struct {
	trackRepository   repository.TrackRepository
	playlistPresenter presenter.PlaylistPresenter
}

func NewPlaylistUsecase(
	trackRepository repository.TrackRepository,
	playlistPresenter presenter.PlaylistPresenter,
) PlaylistUsecase {
	return PlaylistUsecase{
		trackRepository,
		playlistPresenter,
	}
}
