package playlist_usecase

import (
	"errors"

	"gungun974.com/melodink-server/internal/layers/domain/entities"
	"gungun974.com/melodink-server/internal/layers/domain/repository"
	"gungun974.com/melodink-server/internal/models"
)

func (u *PlaylistUsecase) GetAlbumById(id string) (models.APIResponse, error) {
	playlist, err := u.playlistRepository.GetAlbumById(id)
	if err != nil {
		if errors.Is(err, repository.PlaylistNotFoundError) {
			return nil, entities.NewNotFoundError("Album not found")
		}

		return nil, entities.NewInternalError(err)
	}

	return u.playlistPresenter.ShowPlaylist(playlist), nil
}
