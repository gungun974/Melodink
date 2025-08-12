package track_usecase

import (
	"context"
	"errors"
	"io"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *TrackUsecase) ChangeTrackCover(
	ctx context.Context,
	trackId int,
	file io.Reader,
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

	err = u.coverStorage.UploadCustomTrackCover(track, file)
	if err != nil {
		logger.MainLogger.Error("Failed to save uploaded Cover")
		return nil, err
	}

	track.CoverSignature = u.coverStorage.GetTrackCoverSignature(track)

	err = u.trackRepository.UpdateTrack(track)
	if err != nil {
		logger.MainLogger.Error("Failed to update track cover signature in database")
	}

	track.Scores, err = u.trackRepository.GetAllScoresByTrack(track.Id)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	return u.trackPresenter.ShowTrack(ctx, *track), nil
}
