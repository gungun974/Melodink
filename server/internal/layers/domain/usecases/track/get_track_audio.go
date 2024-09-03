package track_usecase

import (
	"context"
	"errors"
	"os"

	"github.com/gabriel-vasile/mimetype"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *TrackUsecase) GetTrackAudio(
	ctx context.Context,
	trackId int,
) (models.APIResponse, error) {
	track, err := u.trackRepository.GetTrack(trackId)
	if err != nil {
		if errors.Is(err, repository.TrackNotFoundError) {
			return nil, entities.NewNotFoundError("Track not found")
		}
		return nil, entities.NewInternalError(err)
	}

	mtype, err := mimetype.DetectFile(track.Path)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	file, err := os.Open(track.Path)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	fileInfo, err := file.Stat()
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	return models.ReaderAPIResponse{
		MIMEType: mtype.String(),
		Reader:   file,
		Size:     fileInfo.Size(),
	}, nil
}
