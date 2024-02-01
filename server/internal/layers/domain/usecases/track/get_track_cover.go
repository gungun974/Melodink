package track_usecase

import (
	"bytes"
	"errors"
	"os"

	"github.com/dhowden/tag"
	"gungun974.com/melodink-server/internal/models"
)

func (u *TrackUsecase) GetTrackCover(id int) (models.APIResponse, error) {
	track, err := u.trackRepository.GetTrack(id)
	if err != nil {
		return nil, err
	}

	file, err := os.Open(track.Path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	metadata, err := tag.ReadFrom(file)
	if err != nil {
		return nil, err
	}

	picture := metadata.Picture()

	if picture == nil {
		return nil, errors.New("No image found in track")
	}

	return &models.ImageAPIResponse{
		MIMEType: picture.MIMEType,
		Data:     *bytes.NewBuffer(picture.Data),
	}, nil
}
