package hls_usecase

import (
	"github.com/gungun974/Melodink/server/internal/logger"
)

func (u *HlsUsecase) CleanOldStreams() error {
	err := u.hlsProcessor.CleanOldStreams()
	if err != nil {
		logger.MainLogger.Error(err)
		return err
	}

	return nil
}
