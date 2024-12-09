package controller

import (
	"context"
	"io"
	"mime/multipart"
	"net/http"
	"time"

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
	performAdvancedScan bool,
	advancedScanOnlyReplaceEmptyFields bool,
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

	return c.trackUsecase.UploadTrack(ctx,
		file,
		performAdvancedScan,
		advancedScanOnlyReplaceEmptyFields,
	)
}

func (c *TrackController) ScanTrack(
	ctx context.Context,
	rawId string,
	performAdvancedScan bool,
	advancedScanOnlyReplaceEmptyFields bool,
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

	return c.trackUsecase.ScanTrack(
		ctx,
		id,
		performAdvancedScan,
		advancedScanOnlyReplaceEmptyFields,
	)
}

func (c *TrackController) ListUserTracks(
	ctx context.Context,
) (models.APIResponse, error) {
	return c.trackUsecase.ListUserTracks(ctx)
}

func (c *TrackController) ListPendingImportTracks(
	ctx context.Context,
) (models.APIResponse, error) {
	return c.trackUsecase.ListPendingImportTracks(ctx)
}

func (c *TrackController) ImportPendingTracks(
	ctx context.Context,
) (models.APIResponse, error) {
	return c.trackUsecase.ImportPendingTracks(ctx)
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

func (c *TrackController) GetCompressedCover(
	ctx context.Context,
	rawId string,
	quality string,
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

	return c.trackUsecase.GetCompressedTrackCover(ctx, id, quality)
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

func (c *TrackController) GetTrackAudioWithTranscode(
	ctx context.Context,
	rawId string,
	quality string,
	w http.ResponseWriter, r *http.Request,
) error {
	id, err := validator.CoerceAndValidateInt(
		rawId,
		validator.IntValidators{
			validator.IntMinValidator{Min: 0},
		},
	)
	if err != nil {
		return entities.NewValidationError(err.Error())
	}

	return c.trackUsecase.GetTrackAudioWithTranscode(
		ctx,
		id,
		track_usecase.AudioTranscodeQuality(quality),
		w,
		r,
	)
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

	rawGenres, ok := bodyData["genres"].([]any)
	if !ok {
		return nil, entities.NewValidationError(
			"genres should be an array",
		)
	}

	genres := make([]string, 0, len(rawGenres))

	for _, rawGenre := range rawGenres {
		genre, ok := rawGenre.(string)

		if !ok {
			return nil, entities.NewValidationError(
				"genres should be an array of string",
			)
		}

		if _, err := validator.ValidateString(
			genre,
			validator.StringValidators{
				validator.StringMinValidator{Min: 0},
			},
		); err != nil {
			return nil, entities.NewValidationError(err.Error())
		}

		genres = append(genres, genre)
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

	acoustId, err := validator.ValidateMapString(
		"acoust_id",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	musicBrainzReleaseId, err := validator.ValidateMapString(
		"music_brainz_release_id",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	musicBrainzTrackId, err := validator.ValidateMapString(
		"music_brainz_track_id",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	musicBrainzRecordingId, err := validator.ValidateMapString(
		"music_brainz_recording_id",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 0},
		},
	)
	if err != nil {
		return nil, entities.NewValidationError(err.Error())
	}

	var dateAdded *time.Time = nil

	if _, ok := bodyData["date_added"]; ok {
		rawDateAdded, err := validator.ValidateMapString(
			"date_added",
			bodyData,
			validator.StringValidators{},
		)
		if err != nil {
			return nil, entities.NewValidationError(err.Error())
		}
		date, err := time.Parse(time.RFC3339, rawDateAdded)
		if err != nil {
			return nil, entities.NewValidationError(err.Error())
		}

		dateAdded = &date
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

		Genres:  genres,
		Lyrics:  lyrics,
		Comment: comment,

		Artists:      artists,
		AlbumArtists: albumArtists,
		Composer:     composer,

		AcoustID: acoustId,

		MusicBrainzReleaseId:   musicBrainzReleaseId,
		MusicBrainzTrackId:     musicBrainzTrackId,
		MusicBrainzRecordingId: musicBrainzRecordingId,

		DateAdded: dateAdded,
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
		"audio/x-m4a",
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
