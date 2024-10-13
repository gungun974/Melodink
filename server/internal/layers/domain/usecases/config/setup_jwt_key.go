package config_usecase

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"errors"

	config_key "github.com/gungun974/Melodink/server/internal/config"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/logger"
)

func (u *ConfigUsecase) SetupJWTKey(
	ctx context.Context,
) {
	_, err := u.configRepository.GetString(config_key.CONFIG_KEY_JWT)

	if err == nil {
		return
	}

	if !errors.Is(err, repository.ConfigKeyNotFoundError) {
		logger.MainLogger.Fatalf("Can't verify JWT Key exist or not %v", err)
		return
	}

	newKey, err := generateSecretKey(64)
	if err != nil {
		logger.MainLogger.Fatalf("Can't generate a random JWT Key %v", err)
		return
	}

	err = u.configRepository.SetString(config_key.CONFIG_KEY_JWT, newKey)
	if err != nil {
		logger.MainLogger.Fatalf("Can't save generated JWT Key %v", err)
		return
	}

	logger.MainLogger.Info("A brand new JWT key have been generated")
}

func generateSecretKey(length int) (string, error) {
	key := make([]byte, length)

	if _, err := rand.Read(key); err != nil {
		return "", err
	}
	return base64.URLEncoding.EncodeToString(key), nil
}
