package presenter

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

func (p *TrackPresenter) ShowDetailedTracks(
	ctx context.Context,
	tracks []entities.Track,
) models.APIResponse {
	tracksViewModels := make([]view_models.TrackViewModel, len(tracks))

	for i, track := range tracks {
		tracksViewModels[i] = view_models.ConvertToTrackViewModel(ctx, track)
	}

	return models.JsonAPIResponse{
		Data: tracksViewModels,
	}
}

func (p *TrackPresenter) ShowDetailedTrack(
	ctx context.Context,
	track entities.Track,
) models.APIResponse {
	return models.JsonAPIResponse{
		Data: view_models.ConvertToTrackViewModel(ctx, track),
	}
}

func (p *TrackPresenter) ShowMinimalTracks(
	ctx context.Context,
	tracks []entities.Track,
) models.APIResponse {
	tracksViewModels := make([]view_models.MinimalTrackViewModel, len(tracks))

	for i, track := range tracks {
		tracksViewModels[i] = view_models.ConvertToMinimalTrackViewModel(ctx, track)
	}

	return models.JsonAPIResponse{
		Data: tracksViewModels,
	}
}
