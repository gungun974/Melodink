package presenter

import (
	"context"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	view_models "github.com/gungun974/Melodink/server/internal/layers/presentation/models"
	"github.com/gungun974/Melodink/server/internal/models"
)

func NewArtistPresenter() ArtistPresenter {
	return ArtistPresenter{}
}

type ArtistPresenter struct{}

func (p *ArtistPresenter) ShowArtists(
	ctx context.Context,
	artists []entities.Artist,
) models.APIResponse {
	return models.JsonAPIResponse{
		Data: view_models.ConvertToArtistsViewModel(ctx, artists),
	}
}

func (p *ArtistPresenter) ShowAllArtistTracks(
	ctx context.Context,
	artist entities.Artist,
) models.APIResponse {
	artist.Albums = nil

	return models.JsonAPIResponse{
		Data: view_models.ConvertToArtistViewModel(ctx, artist),
	}
}

func (p *ArtistPresenter) ShowAllArtistAlbums(
	ctx context.Context,
	artist entities.Artist,
) models.APIResponse {
	artist.AllTracks = nil

	return models.JsonAPIResponse{
		Data: view_models.ConvertToArtistViewModel(ctx, artist),
	}
}
