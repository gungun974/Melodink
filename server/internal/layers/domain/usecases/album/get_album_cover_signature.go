package album_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *AlbumUsecase) GetAlbumCoverSignature(
	ctx context.Context,
	albumId int,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	album, err := u.albumRepository.GetAlbumById(user.Id)
	if err != nil {
		if errors.Is(err, repository.AlbumNotFoundError) {
			return nil, entities.NewNotFoundError("Album not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if album.UserId != nil && *album.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	if len(album.Tracks) <= 0 {
		return nil, entities.NewNotFoundError(
			"No image available for this album",
		)
	}

	signature := u.coverStorage.GetAlbumCoverSignature(album)

	if signature != "" {
		return models.PlainAPIResponse{
			Text: signature,
		}, nil
	}

	for _, track := range album.Tracks {
		signature := u.coverStorage.GetTrackCoverSignature(&track)

		if signature != "" {
			return models.PlainAPIResponse{
				Text: signature,
			}, nil
		}
	}

	return models.PlainAPIResponse{
		Text: "",
	}, nil
}
