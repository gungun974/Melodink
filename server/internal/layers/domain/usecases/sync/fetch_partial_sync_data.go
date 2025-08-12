package sync_usecase

import (
	"context"
	"sync"
	"time"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *SyncUsecase) FetchPartialSyncData(
	ctx context.Context,
	since time.Time,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	var tracks []entities.Track
	var albums []entities.Album
	var artists []entities.Artist
	var playlists []entities.Playlist

	var deletedTracks []int
	var deletedAlbums []int
	var deletedArtists []int
	var deletedPlaylists []int

	var errTracks error
	var errAlbums error
	var errArtists error
	var errPlaylists error

	now := time.Now()

	var wg sync.WaitGroup

	wg.Add(4)

	go func() {
		defer wg.Done()
		tracks, errTracks = u.trackRepository.GetAllTracksFromUserSince(user.Id, since)
		if errTracks != nil {
			return
		}
		deletedTracks, errTracks = u.trackRepository.GetAllDeletedTracksSince(since)
	}()

	go func() {
		defer wg.Done()
		albums, errAlbums = u.albumRepository.GetAllAlbumsFromUserSince(user.Id, since)
		if errAlbums != nil {
			return
		}
		errAlbums = u.albumRepository.LoadTracksInAlbums(albums)
		if errAlbums != nil {
			return
		}
		for i := range albums {
			u.coverStorage.LoadAlbumCoverSignature(&albums[i])
		}
		deletedAlbums, errAlbums = u.albumRepository.GetAllDeletedAlbumsSince(since)
	}()

	go func() {
		defer wg.Done()
		artists, errArtists = u.artistRepository.GetAllArtistsFromUserSince(user.Id, since)
		if errArtists != nil {
			return
		}
		deletedArtists, errArtists = u.artistRepository.GetAllDeletedArtistsSince(since)
	}()

	go func() {
		defer wg.Done()
		playlists, errPlaylists = u.playlistRepository.GetAllPlaylistsFromUserSince(user.Id, since)
		if errPlaylists != nil {
			return
		}
		for i := range playlists {
			u.coverStorage.LoadPlaylistCoverSignature(&playlists[i])
		}
		deletedPlaylists, errPlaylists = u.playlistRepository.GetAllDeletedPlaylistsSince(since)
	}()

	wg.Wait()

	if errTracks != nil {
		return nil, entities.NewInternalError(errTracks)
	}

	if errAlbums != nil {
		return nil, entities.NewInternalError(errAlbums)
	}

	if errArtists != nil {
		return nil, entities.NewInternalError(errArtists)
	}

	if errPlaylists != nil {
		return nil, entities.NewInternalError(errPlaylists)
	}

	return u.syncPresenter.ShowPartialSync(
		ctx,
		tracks,
		albums,
		artists,
		playlists,
		deletedTracks,
		deletedAlbums,
		deletedArtists,
		deletedPlaylists,
		now,
	), nil
}
