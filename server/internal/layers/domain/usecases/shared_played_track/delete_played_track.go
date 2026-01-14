package shared_played_track_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *SharedPlayedTrackUsecase) DeletePlayedTrack(
	ctx context.Context,
	playedTrackId int,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	playedTrack, err := u.sharedPlayedTrackRepository.GetPlayedTrackById(playedTrackId)
	if err != nil {
		if errors.Is(err, repositories.PlayedTrackNotFoundError) {
			return nil, entities.NewNotFoundError("PlayedTrack not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if playedTrack.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	if err := u.sharedPlayedTrackRepository.DeleteSharedPlayedTrack(playedTrack); err != nil {
		logger.MainLogger.Error("Couldn't delete PlayedTrack from Database", err, *playedTrack)
		return nil, entities.NewInternalError(errors.New("Failed to delete PlayedTrack"))
	}

	return u.sharedPlayedTrackPresenter.ShowSharedPlayedTrack(*playedTrack), nil
}
