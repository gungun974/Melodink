package shared_played_track_usecase

import (
	"context"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *SharedPlayedTrackUsecase) GetSharedPlayedTracksFromIdToLast(
	ctx context.Context,
	fromId int,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	sharedPlayedTracks, err := u.sharedPlayedTrackRepository.GetSharedPlayedTracksFromIdToLast(
		user.Id,
		fromId,
	)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	return u.sharedPlayedTrackPresenter.ShowSharedPlayedTracks(sharedPlayedTracks), nil
}
