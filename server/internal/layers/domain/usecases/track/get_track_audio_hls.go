package track_usecase

import (
	"context"
	"errors"
	"fmt"
	"net/http"

	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

type AudioHlsQuality string

const (
	AudioHlsAdaptative AudioHlsQuality = "adaptative"
	AudioHlsLoseless   AudioHlsQuality = "loseless"
	AudioHlsHigh       AudioHlsQuality = "high"
	AudioHlsMedium     AudioHlsQuality = "medium"
	AudioHlsLow        AudioHlsQuality = "low"
)

func (u *TrackUsecase) GetTrackAudioHls(
	ctx context.Context,
	trackId int,
	quality AudioHlsQuality,
) (models.APIResponse, error) {
	track, err := u.trackRepository.GetTrack(trackId)
	if err != nil {
		if errors.Is(err, repository.TrackNotFoundError) {
			return nil, entities.NewNotFoundError("Track not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if quality == AudioHlsLoseless {
		go (func() {
			err := u.hlsProcessor.GenerateMaxStream(track)
			if err != nil {
				logger.MainLogger.Error(err)
			}
		})()

		return models.RedirectAPIResponse{
			Status: http.StatusSeeOther,
			Url:    fmt.Sprintf("/hls/%d/flac_orig.m3u8", track.Id),
		}, nil
	}

	if quality == AudioHlsHigh {
		go (func() {
			err := u.hlsProcessor.Generate44kStream(track)
			if err != nil {
				logger.MainLogger.Error(err)
			}
		})()

		return models.RedirectAPIResponse{
			Status: http.StatusSeeOther,
			Url:    fmt.Sprintf("/hls/%d/flac_44k.m3u8", track.Id),
		}, nil
	}

	if quality == AudioHlsMedium {
		go (func() {
			err := u.hlsProcessor.Generate320Stream(track)
			if err != nil {
				logger.MainLogger.Error(err)
			}
		})()

		return models.RedirectAPIResponse{
			Status: http.StatusSeeOther,
			Url:    fmt.Sprintf("/hls/%d/320k.m3u8", track.Id),
		}, nil
	}

	if quality == AudioHlsLow {
		go (func() {
			err := u.hlsProcessor.Generate96Stream(track)
			if err != nil {
				logger.MainLogger.Error(err)
			}
		})()

		return models.RedirectAPIResponse{
			Status: http.StatusSeeOther,
			Url:    fmt.Sprintf("/hls/%d/96k.m3u8", track.Id),
		}, nil
	}

	go (func() {
		err := u.hlsProcessor.GenerateAdaptativeStream(track)
		if err != nil {
			logger.MainLogger.Error(err)
		}
	})()

	return models.RedirectAPIResponse{
		Status: http.StatusSeeOther,
		Url:    fmt.Sprintf("/hls/%d/master.m3u8", track.Id),
	}, nil
}
