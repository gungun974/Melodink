package track_usecase

import (
	"context"
	"io"
	"os"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *TrackUsecase) UploadTrack(
	ctx context.Context,
	file io.Reader,
	performAdvancedScan bool,
	advancedScanOnlyReplaceEmptyFields bool,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	path, err := u.trackStorage.UploadAudioFile(user.Id, file)
	if err != nil {
		logger.MainLogger.Error("Failed to save uploaded Audio File")
		return nil, err
	}

	track, err := scanAudio(path)
	if err != nil {
		logger.MainLogger.Error("Failed to scan audio")
		os.Remove(path)
		return nil, err
	}

	if performAdvancedScan {
		track, err = u.advancedScanTrack(track, advancedScanOnlyReplaceEmptyFields)
		if err != nil {
			logger.MainLogger.Errorf("Failed to perform an advanced scan %v", err)
			os.Remove(path)
			return nil, err
		}
	}

	track.UserId = &user.Id
	track.PendingImport = true

	err = u.trackRepository.CreateTrack(&track)
	if err != nil {
		logger.MainLogger.Error("Failed to save audio data in database")
		os.Remove(path)
		return nil, err
	}

	err = u.trackStorage.MoveAudioFile(&track)
	if err != nil {
		logger.MainLogger.Error("Failed to move audio to sorted directory")
		if err := u.trackRepository.DeleteTrack(&track); err != nil {
			logger.MainLogger.Error("Failed to delete broken track from database")
			return nil, err
		}
		return nil, err
	}

	err = u.trackRepository.UpdateTrackPath(&track)
	if err != nil {
		logger.MainLogger.Error("Failed to update track path in database")

		if err := u.trackRepository.DeleteTrack(&track); err != nil {
			logger.MainLogger.Error("Failed to delete broken track from database")
			return nil, err
		}
		return nil, err
	}

	err = u.coverStorage.GenerateTrackCoverFromAudioFile(&track)
	if err != nil {
		logger.MainLogger.Warn("Failed to extract cover from audio file", err)
	} else {
		track.CoverSignature = u.coverStorage.GetTrackCoverSignature(&track)

		err = u.trackRepository.UpdateTrack(&track)
		if err != nil {
			logger.MainLogger.Error("Failed to update track cover signature in database")
		}
	}

	return u.trackPresenter.ShowDetailedTrack(track), nil
}
