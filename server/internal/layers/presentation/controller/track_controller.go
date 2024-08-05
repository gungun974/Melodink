package controller

import (
	"context"
	"io"
	"mime/multipart"
	"net/http"

	"github.com/gabriel-vasile/mimetype"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	track_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/track"
	"github.com/gungun974/Melodink/server/internal/models"
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

func (c *TrackController) UploadAudio(
	ctx context.Context,
	r *http.Request,
) (models.APIResponse, error) {
	file, handler, err := r.FormFile("audio")
	if err == nil {
		defer file.Close()

		if err := checkIfFileIsAudioFile(file, handler); err != nil {
			return nil, err
		}
	} else {
		return nil, entities.NewValidationError("File can't be open")
	}

	return c.trackUsecase.UploadTrack(ctx, file)
}

func checkIfFileIsAudioFile(file io.ReadSeeker, handler *multipart.FileHeader) error {
	if handler.Size > 500*1024*1024 {
		return entities.NewValidationError("File is too big")
	}

	validMimeType := false

	mtype, err := mimetype.DetectReader(file)
	if err != nil {
		return entities.NewValidationError("File type is unknown")
	}

	if _, err := file.Seek(0, io.SeekStart); err != nil {
		return entities.NewInternalError(err)
	}

	for _, mimeType := range []string{
		"audio/mpeg",
		"audio/mp4",
		"audio/ogg",
		"audio/vorbis",
		"audio/aac",
		"audio/wav",
		"audio/flac",
		"audio/x-flac",
	} {
		if mimeType == mtype.String() {
			validMimeType = true
			break
		}
	}

	if !validMimeType {
		return entities.NewValidationError("File is not a valid audio file")
	}

	return nil
}
