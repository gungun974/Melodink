package presenter

import (
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	view_models "github.com/gungun974/Melodink/server/internal/layers/presentation/models"
	"github.com/gungun974/Melodink/server/internal/models"
)

func NewArtistPresenter() ArtistPresenter {
	return ArtistPresenter{}
}

type ArtistPresenter struct{}

func (p *ArtistPresenter) ShowArtists(
	artists []entities.Artist,
) models.APIResponse {
	return models.JsonAPIResponse{
		Data: view_models.ConvertToArtistsViewModel(artists),
	}
}

func (p *ArtistPresenter) ShowAllArtistTracks(
	artist entities.Artist,
) models.APIResponse {
	artist.Albums = nil

	return models.JsonAPIResponse{
		Data: view_models.ConvertToArtistViewModel(artist),
	}
}

func (p *ArtistPresenter) ShowAllArtistAlbums(
	artist entities.Artist,
) models.APIResponse {
	artist.AllTracks = nil

	return models.JsonAPIResponse{
		Data: view_models.ConvertToArtistViewModel(artist),
	}
}
