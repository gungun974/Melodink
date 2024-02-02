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

func (c *TrackController) FetchAudioStream(rawId int, rawFormat pb.AudioStreamFormat, rawQuality pb.AudioStreamQuality) (*pb.TrackFetchAudioStreamResponse, error) {
	id, err := validator.ValidateInt(
		rawId,
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
	case pb.AudioStreamFormat_FILE:
		format = entities.AudioStreamFileFormat
	case pb.AudioStreamFormat_HLS:
		format = entities.AudioStreamHLSFormat
	case pb.AudioStreamFormat_DASH:
		format = entities.AudioStreamDashFormat
	default:
		return nil, entities.NewValidationError("Invalid format")
	}

	switch rawQuality {
	case pb.AudioStreamQuality_LOW:
		quality = entities.AudioStreamLowQuality
	case pb.AudioStreamQuality_MEDIUM:
		quality = entities.AudioStreamMediumQuality
	case pb.AudioStreamQuality_HIGH:
		quality = entities.AudioStreamHighQuality
	case pb.AudioStreamQuality_MAX:
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
