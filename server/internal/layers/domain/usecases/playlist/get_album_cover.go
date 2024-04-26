package playlist_usecase

import (
	"bytes"
	"errors"
	"fmt"
	"os"

	"github.com/dhowden/tag"
	"gungun974.com/melodink-server/internal/layers/domain/entities"
	"gungun974.com/melodink-server/internal/layers/domain/repository"
	"gungun974.com/melodink-server/internal/models"
)

func (u *PlaylistUsecase) GetAlbumCover(id string) (models.APIResponse, error) {
	album, err := u.playlistRepository.GetAlbumById(id)
	if err != nil {
		if errors.Is(err, repository.PlaylistNotFoundError) {
			return nil, entities.NewNotFoundError(
				fmt.Sprintf("Album \"%s\" not found", id),
			)
		}
		return nil, entities.NewInternalError(err)
	}

	if len(album.Tracks) == 0 {
		return nil, entities.NewNotFoundError(
			fmt.Sprintf("No image available for album \"%s\"", id),
		)
	}

	file, err := os.Open(album.Tracks[0].Path)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}
	defer file.Close()

	metadata, err := tag.ReadFrom(file)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	picture := metadata.Picture()

	if picture == nil {
		return nil, entities.NewNotFoundError(
			fmt.Sprintf("No image available for album \"%s\"", id),
		)
	}

	return &models.ImageAPIResponse{
		MIMEType: picture.MIMEType,
		Data:     *bytes.NewBuffer(picture.Data),
	}, nil
}
