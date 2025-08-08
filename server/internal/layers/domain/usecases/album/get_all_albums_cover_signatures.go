package album_usecase

import (
	"context"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *AlbumUsecase) GetAllAlbumsCoverSignatures(
	ctx context.Context,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	albums, err := u.albumRepository.GetAllAlbumsFromUser(user.Id)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	results := map[int]string{}

outer:
	for _, album := range albums {

		signature := u.coverStorage.GetAlbumCoverSignature(&album)

		if signature != "" {
			results[album.Id] = signature
			continue
		}

		for _, track := range album.Tracks {
			signature := u.coverStorage.GetTrackCoverSignature(&track)

			if signature != "" {
				results[album.Id] = signature
				continue outer
			}
		}

		results[album.Id] = ""
	}

	return models.JsonAPIResponse{
		Data: results,
	}, nil
}
