package track_usecase

import (
	"bytes"
	"errors"
	"fmt"
	"os"

	"github.com/dhowden/tag"
	"gungun974.com/melodink-server/internal/layers/domain/entities"
	"gungun974.com/melodink-server/internal/layers/domain/repository"
	"gungun974.com/melodink-server/internal/models"
)

func (u *TrackUsecase) GetTrackCover(id int) (models.APIResponse, error) {
	track, err := u.trackRepository.GetTrack(id)
	if err != nil {
		if errors.Is(err, repository.TrackNotFoundError) {
			return nil, entities.NewNotFoundError(
				fmt.Sprintf("Track \"%d\" not found", id),
			)
		}
		return nil, entities.NewInternalError(err)

	}

	file, err := os.Open(track.Path)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}
	defer file.Close()

	metadata, err := tag.ReadFrom(file)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	picture := metadata.Picture()

	if picture == nil {
		return nil, entities.NewNotFoundError(
			fmt.Sprintf("No image available for track \"%d\"", id),
		)
	}

	return &models.ImageAPIResponse{
		MIMEType: picture.MIMEType,
		Data:     *bytes.NewBuffer(picture.Data),
	}, nil
}
