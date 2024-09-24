package controller

import (
	"context"
	"io"
	"mime/multipart"
	"net/http"

	"github.com/gabriel-vasile/mimetype"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	track_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/track"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
	"github.com/gungun974/validator"
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

func (c *TrackController) ListUserTracks(
	ctx context.Context,
) (models.APIResponse, error) {
	return c.trackUsecase.ListUserTracks(ctx)
}

func (c *TrackController) GetTrack(
	ctx context.Context,
	rawId string,
) (models.APIResponse, error) {
	id, err := validator.CoerceAndValidateInt(
		rawId,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.trackUsecase.GetTrackById(ctx, id)
}

func (c *TrackController) GetCover(
	ctx context.Context,
	rawId string,
) (models.APIResponse, error) {
	id, err := validator.CoerceAndValidateInt(
		rawId,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.trackUsecase.GetTrackCover(ctx, id)
}

func (c *TrackController) GetTrackAudio(
	ctx context.Context,
	rawId string,
) (models.APIResponse, error) {
	id, err := validator.CoerceAndValidateInt(
		rawId,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.trackUsecase.GetTrackAudio(ctx, id)
}

func (c *TrackController) GetTrackFileSignature(
	ctx context.Context,
	rawId string,
) (models.APIResponse, error) {
	id, err := validator.CoerceAndValidateInt(
		rawId,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.trackUsecase.GetTrackFileSignature(ctx, id)
}

func (c *TrackController) EditTrack(
	ctx context.Context,
	rawId string,
	bodyData map[string]any,
) (models.APIResponse, error) {
	id, err := validator.CoerceAndValidateInt(
		rawId,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	title, err := validator.ValidateMapString(
		"title",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 1},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	album, err := validator.ValidateMapString(
		"album",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	trackNumber, err := validator.ValidateMapInt(
		"track_number",
		bodyData,
		validator.IntValidators{
			validator.IntMinValidator{Min: -1},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	totalTracks, err := validator.ValidateMapInt(
		"total_tracks",
		bodyData,
		validator.IntValidators{
			validator.IntMinValidator{Min: -1},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	discNumber, err := validator.ValidateMapInt(
		"disc_number",
		bodyData,
		validator.IntValidators{
			validator.IntMinValidator{Min: -1},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	totalDiscs, err := validator.ValidateMapInt(
		"total_discs",
		bodyData,
		validator.IntValidators{
			validator.IntMinValidator{Min: -1},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	date, err := validator.ValidateMapString(
		"date",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	year, err := validator.ValidateMapInt(
		"year",
		bodyData,
		validator.IntValidators{
			validator.IntMinValidator{Min: -1},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	genre, err := validator.ValidateMapString(
		"genre",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	lyrics, err := validator.ValidateMapString(
		"lyrics",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	comment, err := validator.ValidateMapString(
		"comment",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	rawArtists, ok := bodyData["artists"].([]any)
	if !ok {
		return nil, entities.NewValidationError(
			"artists should be an array",
		)
	}

	artists := make([]string, 0, len(rawArtists))

	for _, rawArtist := range rawArtists {
		artist, ok := rawArtist.(string)

		if !ok {
			return nil, entities.NewValidationError(
				"artists should be an array of string",
			)
		}

		if _, err := validator.ValidateString(
			artist,
			validator.StringValidators{
				validator.StringMinValidator{Min: 0},
			},
		); err != nil {
			return nil, entities.NewValidationError(err.Error())
		}

		artists = append(artists, artist)
	}

	rawAlbumArtists, ok := bodyData["album_artists"].([]any)
	if !ok {
		return nil, entities.NewValidationError(
			"artists should be an array",
		)
	}

	albumArtists := make([]string, 0, len(rawAlbumArtists))

	for _, rawAlbumArtist := range rawAlbumArtists {
		artist, ok := rawAlbumArtist.(string)

		if !ok {
			return nil, entities.NewValidationError(
				"artists should be an array of string",
			)
		}

		if _, err := validator.ValidateString(
			artist,
			validator.StringValidators{
				validator.StringMinValidator{Min: 0},
			},
		); err != nil {
			return nil, entities.NewValidationError(err.Error())
		}

		albumArtists = append(albumArtists, artist)
	}

	composer, err := validator.ValidateMapString(
		"composer",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	copyright, err := validator.ValidateMapString(
		"copyright",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.trackUsecase.EditTrack(ctx, track_usecase.EditTrackParams{
		Id: id,

		Title: title,

		Album: album,

		TrackNumber: trackNumber,
		TotalTracks: totalTracks,

		DiscNumber: discNumber,
		TotalDiscs: totalDiscs,

		Date: date,
		Year: year,

		Genre:   genre,
		Lyrics:  lyrics,
		Comment: comment,

		Artists:      artists,
		AlbumArtists: albumArtists,
		Composer:     composer,

		Copyright: copyright,
	})
}

func (c *TrackController) DeleteTrack(
	ctx context.Context,
	rawId string,
) (models.APIResponse, error) {
	id, err := validator.CoerceAndValidateInt(
		rawId,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	return c.trackUsecase.DeleteTrack(ctx, id)
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
		"video/mp4",
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
		logger.MainLogger.Warnf("Can't process %s", mtype.String())
		return entities.NewValidationError("File is not a valid audio file")
	}

	return nil
}
