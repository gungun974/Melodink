package sync_usecase

import (
	"context"
	"sync"
	"time"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/models"
)

func (u *SyncUsecase) FetchFullSyncData(
	ctx context.Context,
) (models.APIResponse, error) {
	user, err := helpers.ExtractCurrentLoggedUser(ctx)
	if err != nil {
		return nil, err
	}

	var tracks []entities.Track
	var albums []entities.Album
	var artists []entities.Artist
	var playlists []entities.Playlist

	var errTracks error
	var errAlbums error
	var errArtists error
	var errPlaylists error

	now := time.Now()

	var wg sync.WaitGroup

	wg.Add(4)

	go func() {
		defer wg.Done()
		tracks, errTracks = u.trackRepository.GetAllTracksFromUser(user.Id)
		if errTracks != nil {
			return
		}
		errTracks = u.trackRepository.LoadAllScoresWithTracks(tracks)
	}()

	go func() {
		defer wg.Done()
		albums, errAlbums = u.albumRepository.GetAllAlbumsFromUser(user.Id)
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
	}()

	go func() {
		defer wg.Done()
		artists, errArtists = u.artistRepository.GetAllArtistsFromUser(user.Id)
	}()

	go func() {
		defer wg.Done()
		playlists, errPlaylists = u.playlistRepository.GetAllPlaylistsFromUser(user.Id)
		if errPlaylists != nil {
			return
		}
		for i := range playlists {
			u.coverStorage.LoadPlaylistCoverSignature(&playlists[i])
		}
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

	return u.syncPresenter.ShowFullSync(ctx, tracks, albums, artists, playlists, now), nil
}
