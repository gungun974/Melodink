package presenter_impl

import (
	"gungun974.com/melodink-server/internal/layers/domain/entities"
	presenter "gungun974.com/melodink-server/internal/layers/domain/presenters"
	"gungun974.com/melodink-server/internal/layers/presentation/models"
	"gungun974.com/melodink-server/internal/models"
)

type TrackPresenterImpl struct{}

func NewTrackPresenterImpl() presenter.TrackPresenter {
	return &TrackPresenterImpl{}
}

func (p *TrackPresenterImpl) ShowAllTracks(
	tracks []entities.Track,
) models.APIResponse {
	view_tracks := make([]view_models.TrackJson, len(tracks))

	for i, track := range tracks {
		view_tracks[i] = view_models.ConvertToTrackJson(track)
	}

	return models.JsonAPIResponse{
		Data: view_tracks,
	}
}
