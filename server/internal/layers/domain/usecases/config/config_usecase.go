package config_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
)

type ConfigUsecase struct {
	configRepository repository.ConfigRepository
}

func NewConfigUsecase(
	configRepository repository.ConfigRepository,
) ConfigUsecase {
	return ConfigUsecase{
		configRepository,
	}
}
