package track_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *TrackUsecase) SetTrackScore(
	ctx context.Context,
	trackId int,
	score float64,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	track, err := u.trackRepository.GetTrack(trackId)
	if err != nil {
		if errors.Is(err, repository.TrackNotFoundError) {
			return nil, entities.NewNotFoundError("Track not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if track.UserId != nil && *track.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	if _, err := u.trackRepository.SetUserTrackScore(*track, user.Id, score); err != nil {
		logger.MainLogger.Error("Couldn't update track score in Database", err, *track)
		return nil, entities.NewInternalError(errors.New("Failed to update track score"))
	}

	track.Scores, err = u.trackRepository.GetAllScoresByTrack(track.Id)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	return u.trackPresenter.ShowTrack(ctx, *track), nil
}
