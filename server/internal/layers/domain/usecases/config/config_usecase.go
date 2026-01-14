package config_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
)

type ConfigUsecase struct {
	configRepository repositories.ConfigRepository
}

func NewConfigUsecase(
	configRepository repositories.ConfigRepository,
) ConfigUsecase {
	return ConfigUsecase{
		configRepository,
	}
}
