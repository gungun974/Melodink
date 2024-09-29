package track_usecase

import (
	"context"
	"errors"
	"strings"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

type EditTrackParams struct {
	Id int

	Title string

	Album string

	TrackNumber int
	TotalTracks int

	DiscNumber int
	TotalDiscs int

	Date string
	Year int

	Genres  []string
	Lyrics  string
	Comment string

	Artists      []string
	AlbumArtists []string
	Composer     string
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

	track.Metadata.Album = params.Album

	track.Metadata.TrackNumber = params.TrackNumber
	track.Metadata.TotalTracks = params.TotalTracks

	track.Metadata.DiscNumber = params.DiscNumber
	track.Metadata.TotalDiscs = params.TotalDiscs

	track.Metadata.Date = params.Date
	track.Metadata.Year = params.Year

	track.Metadata.Genres = params.Genres
	track.Metadata.Lyrics = params.Lyrics
	track.Metadata.Comment = params.Comment

	for i := range params.Artists {
		params.Artists[i] = strings.TrimSpace(params.Artists[i])
	}

	for i := range params.AlbumArtists {
		params.AlbumArtists[i] = strings.TrimSpace(params.AlbumArtists[i])
	}

	params.Artists = helpers.RemoveEmptyStrings(params.Artists)
	params.AlbumArtists = helpers.RemoveEmptyStrings(params.AlbumArtists)

	track.Metadata.Artists = params.Artists
	track.Metadata.AlbumArtists = params.AlbumArtists
	track.Metadata.Composer = params.Composer

	if err := u.trackRepository.UpdateTrack(track); err != nil {
		logger.MainLogger.Error("Couldn't update track in Database", err, *track)
		return nil, entities.NewInternalError(errors.New("Failed to update track"))
	}

	return u.trackPresenter.ShowDetailedTrack(*track), nil
}
