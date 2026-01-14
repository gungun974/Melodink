package album_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/data/storages"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenters"
)

type AlbumUsecase struct {
	albumRepository  repositories.AlbumRepository
	trackRepository  repositories.TrackRepository
	artistRepository repositories.ArtistRepository
	coverStorage     storages.CoverStorage
	albumPresenter   presenters.AlbumPresenter
}

func NewAlbumUsecase(
	albumRepository repositories.AlbumRepository,
	trackRepository repositories.TrackRepository,
	artistRepository repositories.ArtistRepository,
	coverStorage storages.CoverStorage,
	albumPresenter presenters.AlbumPresenter,
) AlbumUsecase {
	return AlbumUsecase{
		albumRepository,
		trackRepository,
		artistRepository,
		coverStorage,
		albumPresenter,
	}
}
