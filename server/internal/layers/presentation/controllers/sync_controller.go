package controllers

import (
	"context"
	"time"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	sync_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/sync"
	"github.com/gungun974/Melodink/server/internal/models"
)

type SyncController struct {
	syncUsecase sync_usecase.SyncUsecase
}

func NewSyncController(
	syncUsecase sync_usecase.SyncUsecase,
) SyncController {
	return SyncController{
		syncUsecase,
	}
}

func (c *SyncController) FetchFullSyncData(
	ctx context.Context,
) (models.APIResponse, error) {
	return c.syncUsecase.FetchFullSyncData(ctx)
}

func (c *SyncController) FetchPartialSyncData(
	ctx context.Context,
	rawSince string,
) (models.APIResponse, error) {
	since, err := time.Parse(time.RFC3339, rawSince)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.syncUsecase.FetchPartialSyncData(ctx, since)
}
