package controllers

import (
	"strconv"

	"github.com/gungun974/validator"
	track_usecase "gungun974.com/melodink-server/internal/layers/domain/usecases/track"
	"gungun974.com/melodink-server/internal/models"
	"gungun974.com/melodink-server/pb"
)

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

func (c *TrackController) GetAll() (*pb.TrackList, error) {
	return c.trackUsecase.GetAllTracks()
}

func (c *TrackController) GetCover(rawId string) (models.APIResponse, error) {
	aid, err := strconv.Atoi(rawId)
	if err != nil {
		return nil, err
	}

	id, err := validator.ValidateInt(
		aid,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, err
	}

	return c.trackUsecase.GetTrackCover(id)
}
