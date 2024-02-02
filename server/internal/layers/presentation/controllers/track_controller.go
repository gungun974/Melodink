package controllers

import (
	"strconv"

	"github.com/gungun974/validator"
	"gungun974.com/melodink-server/internal/layers/domain/entities"
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
		return nil, entities.NewValidationError(err.Error())
	}

	id, err := validator.ValidateInt(
		aid,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.trackUsecase.GetTrackCover(id)
}

func (c *TrackController) FetchAudioStream(rawId string, rawFormat string, rawQuality string) (models.APIResponse, error) {
	aid, err := strconv.Atoi(rawId)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	id, err := validator.ValidateInt(
		aid,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	var format entities.AudioStreamFormat
	var quality entities.AudioStreamQuality

	switch rawFormat {
	case "file":
		format = entities.AudioStreamFileFormat
	case "hls":
		format = entities.AudioStreamHLSFormat
	case "dash":
		format = entities.AudioStreamDashFormat
	default:
		return nil, entities.NewValidationError("Invalid format")
	}

	switch rawQuality {
	case "low":
		quality = entities.AudioStreamLowQuality
	case "medium":
		quality = entities.AudioStreamMediumQuality
	case "high":
		quality = entities.AudioStreamHighQuality
	case "max":
		quality = entities.AudioStreamMaxQuality
	default:
		return nil, entities.NewValidationError("Invalid quality")
	}

	return c.trackUsecase.FetchAudioStream(
		track_usecase.FetchAudioStreamParams{
			TrackId:       id,
			StreamFormat:  format,
			StreamQuality: quality,
		},
	)
}
