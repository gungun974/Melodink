package track_usecase

import (
	"context"
	"errors"
	"time"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

type EditTrackParams struct {
	Id int

	Title string

	TrackNumber int
	TotalTracks int

	DiscNumber int
	TotalDiscs int

	Date string
	Year int

	Genres  []string
	Lyrics  string
	Comment string

	Composer string

	AcoustID string

	MusicBrainzReleaseId   string
	MusicBrainzTrackId     string
	MusicBrainzRecordingId string

	DateAdded *time.Time
}

func (u *TrackUsecase) EditTrack(
	ctx context.Context,
	params EditTrackParams,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	track, err := u.trackRepository.GetTrack(params.Id)
	if err != nil {
		if errors.Is(err, repository.TrackNotFoundError) {
			return nil, entities.NewNotFoundError("Track not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if track.UserId != nil && *track.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	track.Title = params.Title

	track.Metadata.TrackNumber = params.TrackNumber
	track.Metadata.TotalTracks = params.TotalTracks

	track.Metadata.DiscNumber = params.DiscNumber
	track.Metadata.TotalDiscs = params.TotalDiscs

	track.Metadata.Date = params.Date
	track.Metadata.Year = params.Year

	track.Metadata.Genres = params.Genres
	track.Metadata.Lyrics = params.Lyrics
	track.Metadata.Comment = params.Comment

	track.Metadata.Composer = params.Composer

	track.Metadata.AcoustID = params.AcoustID

	track.Metadata.MusicBrainzReleaseId = params.MusicBrainzReleaseId
	track.Metadata.MusicBrainzTrackId = params.MusicBrainzTrackId
	track.Metadata.MusicBrainzRecordingId = params.MusicBrainzRecordingId

	if params.DateAdded != nil {
		track.DateAdded = *params.DateAdded
	}

	if err := u.trackRepository.UpdateTrack(track); err != nil {
		logger.MainLogger.Error("Couldn't update track in Database", err, *track)
		return nil, entities.NewInternalError(errors.New("Failed to update track"))
	}

	track.Scores, err = u.trackRepository.GetAllScoresByTrack(track.Id)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	return u.trackPresenter.ShowTrack(ctx, *track), nil
}
