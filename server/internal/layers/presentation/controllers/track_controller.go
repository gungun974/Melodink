package controllers

import track_usecase "gungun974.com/melodink-server/internal/layers/domain/usecases/track"

type TrackController struct {
	trackUsecase track_usecase.TrackUsecase
}

func NewTrackController(
	trackUsecase track_usecase.TrackUsecase,
) TrackController {
	return TrackController{
		trackUsecase,
	}
}

func (c *TrackController) DiscoverNewTracks() error {
	return c.trackUsecase.DiscoverNewTracks()
}
