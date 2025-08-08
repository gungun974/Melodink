package track_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
)

type SetTrackArtistsParams struct {
	Id        int
	ArtistIds []int
}

func (u *TrackUsecase) SetTrackArtists(
	ctx context.Context,
	params SetTrackArtistsParams,
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

	artists := make([]entities.Artist, len(params.ArtistIds))

	for i, trackId := range params.ArtistIds {
		artist, err := u.artistRepository.GetArtistById(trackId)
		if err != nil {
			if errors.Is(err, repository.ArtistNotFoundError) {
				return nil, entities.NewNotFoundError("Artist not found")
			}
			return nil, entities.NewInternalError(err)
		}

		if artist.UserId != nil && *artist.UserId != user.Id {
			return nil, entities.NewUnauthorizedError()
		}

		artists[i] = *artist
	}

	track.Artists = artists

	if err := u.trackRepository.SetTrackArtists(track); err != nil {
		logger.MainLogger.Error("Couldn't set track artists", err, track)
		return nil, entities.NewInternalError(errors.New("Failed to set track artists"))
	}

	return u.trackPresenter.ShowDetailedTrack(ctx, *track), nil
}
