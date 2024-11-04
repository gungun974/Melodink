package controller

import (
	"context"
	"time"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	shared_played_track_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/shared_played_track"
	"github.com/gungun974/Melodink/server/internal/models"
	"github.com/gungun974/validator"
)

type SharedPlayedTrackController struct {
	sharedPlayedTrackUsecase shared_played_track_usecase.SharedPlayedTrackUsecase
}

func NewSharedPlayedTrackController(
	sharedPlayedTrackUsecase shared_played_track_usecase.SharedPlayedTrackUsecase,
) SharedPlayedTrackController {
	return SharedPlayedTrackController{
		sharedPlayedTrackUsecase,
	}
}

func (c *SharedPlayedTrackController) GetFromIdToLast(
	ctx context.Context,
	rawFromId string,
) (models.APIResponse, error) {
	fromId, err := validator.CoerceAndValidateInt(
		rawFromId,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.sharedPlayedTrackUsecase.GetSharedPlayedTracksFromIdToLast(ctx, fromId)
}

func (c *SharedPlayedTrackController) UploadPlayedTrack(
	ctx context.Context,
	bodyData map[string]any,
) (models.APIResponse, error) {
	internalDeviceId, err := validator.ValidateMapInt(
		"internal_device_id",
		bodyData,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	deviceId, err := validator.ValidateMapString(
		"device_id",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 1},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	trackId, err := validator.ValidateMapInt(
		"track_id",
		bodyData,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	rawStartAt, err := validator.ValidateMapString(
		"start_at",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 1},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	startAt, err := time.Parse(time.RFC3339, rawStartAt)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	rawFinishAt, err := validator.ValidateMapString(
		"finish_at",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 1},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	finishAt, err := time.Parse(time.RFC3339, rawFinishAt)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	beginAt, err := validator.ValidateMapInt(
		"begin_at",
		bodyData,
		validator.IntValidators{},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	endedAt, err := validator.ValidateMapInt(
		"ended_at",
		bodyData,
		validator.IntValidators{},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	shuffle, err := validator.ValidateMapBool(
		"shuffle",
		bodyData,
		validator.BoolValidators{},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	trackEnded, err := validator.ValidateMapBool(
		"track_ended",
		bodyData,
		validator.BoolValidators{},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.sharedPlayedTrackUsecase.UploadPlayedTrack(
		ctx,
		shared_played_track_usecase.UploadPlayedTrackParams{
			InternalDeviceId: internalDeviceId,

			DeviceId: deviceId,

			TrackId: trackId,

			StartAt:  startAt,
			FinishAt: finishAt,

			BeginAt: beginAt,
			EndedAt: endedAt,

			Shuffle: shuffle,

			TrackEnded: trackEnded,
		},
	)
}
