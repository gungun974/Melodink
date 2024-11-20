package hls_usecase

import (
	"errors"

	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
)

func (u *HlsUsecase) MarkStreamUse(
	trackId int,
) error {
	track, err := u.trackRepository.GetTrack(trackId)
	if err != nil {
		if errors.Is(err, repository.TrackNotFoundError) {
			return entities.NewNotFoundError("Track not found")
		}
		return entities.NewInternalError(err)
	}

	err = u.hlsProcessor.MarkStreamUse(track)
	if err != nil {
		logger.MainLogger.Error(err)
		return err
	}

	return nil
}
