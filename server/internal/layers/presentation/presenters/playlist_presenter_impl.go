package presenter_impl

import (
	"gungun974.com/melodink-server/internal/layers/domain/entities"
	presenter "gungun974.com/melodink-server/internal/layers/domain/presenters"
	view_models "gungun974.com/melodink-server/internal/layers/presentation/models"
	"gungun974.com/melodink-server/internal/models"
)

type PlaylistPresenterImpl struct{}

func NewPlaylistPresenterImpl() presenter.PlaylistPresenter {
	return &PlaylistPresenterImpl{}
}

func (p *PlaylistPresenterImpl) ShowAllPlaylists(
	playlists []entities.Playlist,
) models.APIResponse {
	view_playlists := make([]view_models.PlaylistJson, len(playlists))

	for i, playlist := range playlists {
		playlist.Tracks = make([]entities.Track, 0)

		view_playlists[i] = view_models.ConvertToPlaylistJson(playlist)
	}

	return models.JsonAPIResponse{
		Data: view_playlists,
	}
}

func (p *PlaylistPresenterImpl) ShowPlaylist(
	playlist entities.Playlist,
) models.APIResponse {
	return models.JsonAPIResponse{
		Data: view_models.ConvertToPlaylistJson(playlist),
	}
}
