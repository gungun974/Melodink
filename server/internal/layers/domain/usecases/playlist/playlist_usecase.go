package playlist_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/data/storages"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenters"
)

type PlaylistUsecase struct {
	playlistRepository repositories.PlaylistRepository
	trackRepository    repositories.TrackRepository
	coverStorage       storages.CoverStorage
	playlistPresenter  presenters.PlaylistPresenter
}

func NewPlaylistUsecase(
	playlistRepository repositories.PlaylistRepository,
	trackRepository repositories.TrackRepository,
	coverStorage storages.CoverStorage,
	playlistPresenter presenters.PlaylistPresenter,
) PlaylistUsecase {
	return PlaylistUsecase{
		playlistRepository,
		trackRepository,
		coverStorage,
		playlistPresenter,
	}
}
