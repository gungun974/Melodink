package track_usecase

import (
	"context"
	"io"

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
		return nil, err
	}

	if performAdvancedScan {
		track, err = u.advancedScanTrack(track, advancedScanOnlyReplaceEmptyFields)
		if err != nil {
			logger.MainLogger.Errorf("Failed to perform an advanced scan %v", err)
			return nil, err
		}
	}

	track.UserId = &user.Id

	err = u.trackStorage.MoveAudioFile(&track)
	if err != nil {
		logger.MainLogger.Error("Failed to move audio to sorted directory")
	}

	err = u.trackRepository.CreateTrack(&track)
	if err != nil {
		logger.MainLogger.Error("Failed to save audio data in database")
	}

	return u.trackPresenter.ShowDetailedTrack(track), nil
}
