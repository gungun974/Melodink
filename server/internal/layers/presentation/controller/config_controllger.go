package controller

import (
	"context"

	config_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/config"
	"github.com/gungun974/Melodink/server/internal/models"
)

type ConfigController struct {
	configUsecase config_usecase.ConfigUsecase
}

func NewConfigController(
	configUsecase config_usecase.ConfigUsecase,
) ConfigController {
	return ConfigController{
		configUsecase,
	}
}

func (c *ConfigController) SetupDefaultKeys(
	ctx context.Context,
) {
	c.configUsecase.SetupJWTKey(ctx)
	c.configUsecase.SetupServerUUID(ctx)
}

func (c *ConfigController) GetServerUUID(
	ctx context.Context,
) models.APIResponse {
	return c.configUsecase.GetServerUUID(ctx)
}
