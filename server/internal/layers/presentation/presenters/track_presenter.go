package presenters

import (
	"context"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	view_models "github.com/gungun974/Melodink/server/internal/layers/presentation/models"
	"github.com/gungun974/Melodink/server/internal/models"
)

func NewTrackPresenter() TrackPresenter {
	return TrackPresenter{}
}

type TrackPresenter struct{}

func (p *TrackPresenter) ShowTracks(
	ctx context.Context,
	tracks []entities.Track,
) models.APIResponse {
	return models.JsonAPIResponse{
		Data: view_models.ConvertToTrackViewModels(ctx, tracks),
	}
}

func (p *TrackPresenter) ShowTrack(
	ctx context.Context,
	track entities.Track,
) models.APIResponse {
	return models.JsonAPIResponse{
		Data: view_models.ConvertToTrackViewModel(ctx, track),
	}
}
