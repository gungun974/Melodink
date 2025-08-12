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

func (u *TrackUsecase) AutoLinkTrack(
	ctx context.Context,
	trackId int,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	track, err := u.trackRepository.GetTrack(trackId)
	if err != nil {
		if errors.Is(err, repository.TrackNotFoundError) {
			return nil, entities.NewNotFoundError("Track not found")
		}
		return nil, entities.NewInternalError(err)
	}

	if track.UserId != nil && *track.UserId != user.Id {
		return nil, entities.NewUnauthorizedError()
	}

	//! Artists

	artists := make([]entities.Artist, len(track.Metadata.Artists))

	for i, targetArtist := range track.Metadata.Artists {
		artist, err := u.artistRepository.GetArtistByNameOrCreate(targetArtist, user.Id)
		if err != nil {
			logger.MainLogger.Error("Couldn't get artist or create new", err, track, targetArtist)
			return nil, entities.NewInternalError(err)
		}

		artists[i] = *artist
	}

	track.Artists = artists

	if err := u.trackRepository.SetTrackArtists(track); err != nil {
		logger.MainLogger.Error("Couldn't set track artists", err, track)
		return nil, entities.NewInternalError(errors.New("Failed to set track artists"))
	}

	//! Album

	albums := make([]entities.Album, 0)

	if !helpers.IsEmptyOrWhitespace(track.Metadata.Album) {
		albumArtists := make([]entities.Artist, len(track.Metadata.AlbumArtists))

		for i, targetArtist := range track.Metadata.AlbumArtists {
			artist, err := u.artistRepository.GetArtistByNameOrCreate(targetArtist, user.Id)
			if err != nil {
				logger.MainLogger.Error(
					"Couldn't get album artist or create new",
					err,
					track,
					targetArtist,
				)
				return nil, entities.NewInternalError(err)
			}

			albumArtists[i] = *artist
		}

		album, err := u.albumRepository.GetAlbumByNameOrCreate(
			track.Metadata.Album,
			albumArtists,
			user.Id,
		)
		if err != nil {
			logger.MainLogger.Error(
				"Couldn't get album or create new",
				err,
				track,
				track.Metadata.Album,
			)
			return nil, entities.NewInternalError(err)
		}

		albums = append(albums, *album)
	}

	track.Albums = albums

	if err := u.trackRepository.SetTrackAlbums(track); err != nil {
		logger.MainLogger.Error("Couldn't set track albums", err, track)
		return nil, entities.NewInternalError(errors.New("Failed to set track albums"))
	}

	return u.trackPresenter.ShowTrack(ctx, *track), nil
}
