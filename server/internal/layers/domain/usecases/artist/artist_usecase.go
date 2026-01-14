package artist_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/data/storages"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenters"
)

type ArtistUsecase struct {
	artistRepository repositories.ArtistRepository
	coverStorage     storages.CoverStorage
	artistPresenter  presenters.ArtistPresenter
}

func NewArtistUsecase(
	artistRepository repositories.ArtistRepository,
	coverStorage storages.CoverStorage,
	artistPresenter presenters.ArtistPresenter,
) ArtistUsecase {
	return ArtistUsecase{
		artistRepository,
		coverStorage,
		artistPresenter,
	}
}
