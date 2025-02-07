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

func (u *TrackUsecase) ChangeTrackAudio(
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

	path, err := u.trackStorage.UploadAudioFile(track.Id, file)
	if err != nil {
		logger.MainLogger.Error("Failed to save uploaded Audio File")
		return nil, err
	}

	track.Path = path

	err = scanAudioFeature(track)
	if err != nil {
		logger.MainLogger.Error("Failed to scan audio")
		return nil, err
	}

	err = u.trackStorage.MoveAudioFile(track)
	if err != nil {
		logger.MainLogger.Error("Failed to move audio to sorted directory")
		return nil, err
	}

	err = u.trackRepository.UpdateTrack(track)
	if err != nil {
		logger.MainLogger.Error("Failed to update track in database")
		return nil, err
	}

	track.Scores, err = u.trackRepository.GetAllScoresByTrack(track.Id)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	_ = u.TranscodeTrack(ctx, track.Id, AudioTranscodeLow)
	_ = u.TranscodeTrack(ctx, track.Id, AudioTranscodeMedium)
	_ = u.TranscodeTrack(ctx, track.Id, AudioTranscodeHigh)

	return u.trackPresenter.ShowDetailedTrack(ctx, *track), nil
}
