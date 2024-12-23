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

func (u *TrackUsecase) ScanTrack(
	ctx context.Context,
	trackId int,
	performAdvancedScan bool,
	advancedScanOnlyReplaceEmptyFields bool,
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

	scannedTrack, err := scanAudio(track.Path)
	if err != nil {
		logger.MainLogger.Error("Failed to scan audio")
		return nil, err
	}

	if performAdvancedScan {
		newScannedTrack, err := u.advancedScanTrack(
			scannedTrack,
			advancedScanOnlyReplaceEmptyFields,
		)
		if err != nil {
			logger.MainLogger.Warnf("Failed to perform an advanced scan %v", err)
		} else {
			scannedTrack = newScannedTrack
		}
	}

	scannedTrack.Id = track.Id
	scannedTrack.UserId = track.UserId

	if len(scannedTrack.Metadata.ArtistsRoles) != 0 {
		track.Metadata.ArtistsRoles = scannedTrack.Metadata.ArtistsRoles

		if err := u.trackRepository.UpdateTrack(track); err != nil {
			logger.MainLogger.Error("Couldn't update track in Database", err, *track)
			return nil, entities.NewInternalError(errors.New("Failed to update track"))
		}
	}

	return u.trackPresenter.ShowDetailedTrack(ctx, scannedTrack), nil
}
