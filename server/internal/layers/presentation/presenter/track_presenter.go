package presenter

import (
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	view_models "github.com/gungun974/Melodink/server/internal/layers/presentation/models"
	"github.com/gungun974/Melodink/server/internal/models"
)

func NewTrackPresenter() TrackPresenter {
	return TrackPresenter{}
}

type TrackPresenter struct{}

func (p *TrackPresenter) ShowDetailedTracks(
	tracks []entities.Track,
) models.APIResponse {
	tracksViewModels := make([]view_models.TrackViewModel, len(tracks))

	for i, track := range tracks {
		tracksViewModels[i] = view_models.ConvertToTrackViewModel(track)
	}

	return models.JsonAPIResponse{
		Data: tracksViewModels,
	}
}

func (p *TrackPresenter) ShowDetailedTrack(
	track entities.Track,
) models.APIResponse {
	return models.JsonAPIResponse{
		Data: view_models.ConvertToTrackViewModel(track),
	}
}

func (p *TrackPresenter) ShowMinimalTracks(
	tracks []entities.Track,
) models.APIResponse {
	tracksViewModels := make([]view_models.MinimalTrackViewModel, len(tracks))

	for i, track := range tracks {
		tracksViewModels[i] = view_models.ConvertToMinimalTrackViewModel(track)
	}

	return models.JsonAPIResponse{
		Data: tracksViewModels,
	}
}
