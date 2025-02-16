package presenter

import (
	"context"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	view_models "github.com/gungun974/Melodink/server/internal/layers/presentation/models"
	"github.com/gungun974/Melodink/server/internal/models"
)

func NewPlaylistPresenter() PlaylistPresenter {
	return PlaylistPresenter{}
}

type PlaylistPresenter struct{}

func (p *PlaylistPresenter) ShowPlaylists(
	ctx context.Context,
	playlists []entities.Playlist,
) models.APIResponse {
	playlistsViewModels := make([]view_models.PlaylistViewModel, len(playlists))

	for i, playlist := range playlists {
		playlistsViewModels[i] = view_models.ConvertToPlaylistViewModel(ctx, playlist)
	}

	return models.JsonAPIResponse{
		Data: playlistsViewModels,
	}
}

func (p *PlaylistPresenter) ShowPlaylist(
	ctx context.Context,
	playlist entities.Playlist,
) models.APIResponse {
	return models.JsonAPIResponse{
		Data: view_models.ConvertToPlaylistViewModel(ctx, playlist),
	}
}
