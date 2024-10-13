package config_usecase

import (
	"context"
	"errors"

	"github.com/google/uuid"
	config_key "github.com/gungun974/Melodink/server/internal/config"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/logger"
)

func (u *ConfigUsecase) SetupServerUUID(
	ctx context.Context,
) {
	_, err := u.configRepository.GetString(config_key.CONFIG_SERVER_UUID)

	if err == nil {
		return
	}

	if !errors.Is(err, repository.ConfigKeyNotFoundError) {
		logger.MainLogger.Fatalf("Can't verify Server UUID Key exist or not %v", err)
		return
	}

	newServerId := uuid.New()

	err = u.configRepository.SetString(config_key.CONFIG_SERVER_UUID, newServerId.String())
	if err != nil {
		logger.MainLogger.Fatalf("Can't save generated Server UUID %v", err)
		return
	}

	logger.MainLogger.Info("A brand new Server UUID have been generated")
}
