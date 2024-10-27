package artist_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/data/storage"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenter"
)

type ArtistUsecase struct {
	artistRepository repository.ArtistRepository
	coverStorage     storage.CoverStorage
	artistPresenter  presenter.ArtistPresenter
}

func NewArtistUsecase(
	artistRepository repository.ArtistRepository,
	coverStorage storage.CoverStorage,
	artistPresenter presenter.ArtistPresenter,
) ArtistUsecase {
	return ArtistUsecase{
		artistRepository,
		coverStorage,
		artistPresenter,
	}
}
