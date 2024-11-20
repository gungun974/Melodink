package controller

import (
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	hls_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/hls"
	"github.com/gungun974/validator"
)

type HlsController struct {
	hlsUsecase hls_usecase.HlsUsecase
}

func NewHlsController(
	hlsUsecase hls_usecase.HlsUsecase,
) HlsController {
	return HlsController{
		hlsUsecase,
	}
}

func (c *HlsController) CleanOldStreams() error {
	return c.hlsUsecase.CleanOldStreams()
}

func (c *HlsController) MarkStreamUse(
	rawId string,
) error {
	id, err := validator.CoerceAndValidateInt(
		rawId,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return entities.NewValidationError(err.Error())
	}

	return c.hlsUsecase.MarkStreamUse(id)
}

func (c *HlsController) CheckStreamSectionReady(
	rawId string,
	file string,
) bool {
	id, err := validator.CoerceAndValidateInt(
		rawId,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return false
	}

	return c.hlsUsecase.CheckStreamSectionReady(id, file)
}
