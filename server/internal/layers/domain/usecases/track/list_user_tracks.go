package track_usecase

import (
	"context"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *TrackUsecase) ListUserTracks(
	ctx context.Context,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	tracks, err := u.trackRepository.GetAllTracksFromUser(user.Id)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	err = u.trackRepository.LoadAllScoresWithTracks(tracks)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	return u.trackPresenter.ShowMinimalTracks(ctx, tracks), nil
}
