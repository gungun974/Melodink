package config_usecase

import (
	"context"

	config_key "github.com/gungun974/Melodink/server/internal/config"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *ConfigUsecase) GetServerUUID(
	ctx context.Context,
) models.APIResponse {
	serverId, err := u.configRepository.GetString(config_key.CONFIG_SERVER_UUID)
	if err != nil {
		logger.MainLogger.Fatalf("Can't find config ServerUUID key %v", err)
	}

	return models.PlainAPIResponse{Text: serverId}
}
