package shared_played_track_usecase

import (
	"context"
	"errors"
	"time"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

type UploadPlayedTrackParams struct {
	InternalDeviceId int

	DeviceId string

	TrackId int

	StartAt  time.Time
	FinishAt time.Time

	BeginAt int
	EndedAt int

	Shuffle bool

	TrackEnded bool

	TrackDuration int
}

func (u *SharedPlayedTrackUsecase) UploadPlayedTrack(
	ctx context.Context,
	params UploadPlayedTrackParams,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	newSharedPlayedTrack := entities.SharedPlayedTrack{
		InternalDeviceId: params.InternalDeviceId,

		UserId: user.Id,

		DeviceId: params.DeviceId,

		TrackId: params.TrackId,

		StartAt:  params.StartAt,
		FinishAt: params.FinishAt,

		BeginAt: params.BeginAt,
		EndedAt: params.EndedAt,

		Shuffle: params.Shuffle,

		TrackEnded: params.TrackEnded,

		TrackDuration: params.TrackDuration,
	}

	if err := u.sharedPlayedTrackRepository.AddSharedPlayedTrack(&newSharedPlayedTrack); err != nil {
		logger.MainLogger.Error(
			"Couldn't add played track to shared table",
			err,
			newSharedPlayedTrack,
		)
		return nil, entities.NewInternalError(errors.New("Failed to add shared played track"))
	}

	return u.sharedPlayedTrackPresenter.ShowSharedPlayedTrack(newSharedPlayedTrack), nil
}
