package album_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/data/storage"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenter"
)

type AlbumUsecase struct {
	albumRepository repository.AlbumRepository
	trackRepository repository.TrackRepository
	coverStorage    storage.CoverStorage
	albumPresenter  presenter.AlbumPresenter
}

func NewAlbumUsecase(
	albumRepository repository.AlbumRepository,
	trackRepository repository.TrackRepository,
	coverStorage storage.CoverStorage,
	albumPresenter presenter.AlbumPresenter,
) AlbumUsecase {
	return AlbumUsecase{
		albumRepository,
		trackRepository,
		coverStorage,
		albumPresenter,
	}
}
