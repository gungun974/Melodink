package playlist_usecase

import (
	"gungun974.com/melodink-server/internal/layers/domain/entities"
	"gungun974.com/melodink-server/internal/models"
)

func (u *PlaylistUsecase) ListAllAlbums() (models.APIResponse, error) {
	playlists, err := u.playlistRepository.GetAllAlbums()
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	return u.playlistPresenter.ShowAllPlaylists(playlists), nil
}
