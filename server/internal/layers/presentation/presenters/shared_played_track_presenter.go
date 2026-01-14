package presenters

import (
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	view_models "github.com/gungun974/Melodink/server/internal/layers/presentation/models"
	"github.com/gungun974/Melodink/server/internal/models"
)

func NewSharedPlayedTrackPresenter() SharedPlayedTrackPresenter {
	return SharedPlayedTrackPresenter{}
}

type SharedPlayedTrackPresenter struct{}

func (p *SharedPlayedTrackPresenter) ShowSharedPlayedTracks(
	playedTracks []entities.SharedPlayedTrack,
) models.APIResponse {
	sharedPlayedtracksViewModels := make(
		[]view_models.SharedPlayedTrackViewModel,
		len(playedTracks),
	)

	for i, playedTrack := range playedTracks {
		sharedPlayedtracksViewModels[i] = view_models.ConvertToSharedPlayedTrackViewModel(
			playedTrack,
		)
	}

	return models.JsonAPIResponse{
		Data: sharedPlayedtracksViewModels,
	}
}

func (p *SharedPlayedTrackPresenter) ShowSharedPlayedTrack(
	playedTrack entities.SharedPlayedTrack,
) models.APIResponse {
	return models.JsonAPIResponse{
		Data: view_models.ConvertToSharedPlayedTrackViewModel(playedTrack),
	}
}
