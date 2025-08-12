package view_models

import (
	"context"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type ArtistViewModel struct {
	Id int `json:"id"`

	UserId *int `json:"user_id"`

	Name string `json:"name"`
}

func ConvertToArtistsViewModel(
	ctx context.Context,
	artists []entities.Artist,
) []ArtistViewModel {
	artistsViewModels := make([]ArtistViewModel, len(artists))

	for i, artist := range artists {
		artistsViewModels[i] = ConvertToArtistViewModel(ctx, artist)
	}

	return artistsViewModels
}

func ConvertToArtistViewModel(
	ctx context.Context,
	artist entities.Artist,
) ArtistViewModel {
	return ArtistViewModel{
		Id: artist.Id,

		UserId: artist.UserId,

		Name: artist.Name,
	}
}
