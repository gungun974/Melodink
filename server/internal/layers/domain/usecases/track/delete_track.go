package track_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *TrackUsecase) DeleteTrack(
	ctx context.Context,
	trackId int,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	track, err := u.trackRepository.GetTrack(trackId)
	if err != nil {
		if errors.Is(err, repositories.TrackNotFoundError) {
			return nil, entities.NewNotFoundError("Track not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if track.UserId != nil && *track.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	if err := u.trackStorage.RemoveAudioFile(track); err != nil {
		logger.MainLogger.Error("Couldn't delete audio file from storage", err, *track)
		return nil, entities.NewInternalError(errors.New("Failed to delete track"))
	}

	if err := u.coverStorage.RemoveTrackCoverFiles(track); err != nil {
		logger.MainLogger.Warn("Couldn't delete cover files from storage", err, *track)
	}

	if err := u.trackRepository.DeleteTrack(track); err != nil {
		logger.MainLogger.Error("Couldn't delete track from Database", err, *track)
		return nil, entities.NewInternalError(errors.New("Failed to delete track"))
	}

	if err := u.transcodeStorage.RemoveTrackTranscocdeDirectry(track.Id); err != nil {
		logger.MainLogger.Warn("Couldn't delete transcode files from storage", err, *track)
	}

	return u.trackPresenter.ShowTrack(ctx, *track), nil
}
