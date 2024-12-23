package track_usecase

import (
	"context"
	"errors"
	"time"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *TrackUsecase) ImportPendingTracks(
	ctx context.Context,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	tracks, err := u.trackRepository.GetAllPendingImportTracksFromUser(user.Id)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	now := time.Now()

	for _, track := range tracks {
		track.DateAdded = now
		track.PendingImport = false

		if err := u.trackRepository.UpdateTrack(&track); err != nil {
			logger.MainLogger.Error("Couldn't update track in Database", err, track)
			return nil, entities.NewInternalError(errors.New("Failed to update track"))
		}
	}

	return u.trackPresenter.ShowMinimalTracks(ctx, tracks), nil
}
