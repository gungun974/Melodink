package presenters

import (
	"context"
	"time"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	view_models "github.com/gungun974/Melodink/server/internal/layers/presentation/models"
	"github.com/gungun974/Melodink/server/internal/models"
)

func NewSyncPresenter() SyncPresenter {
	return SyncPresenter{}
}

type SyncPresenter struct{}

type FullSyncViewModel struct {
	SyncViewModel
	Date string `json:"date"`
}

type PartialSyncViewModel struct {
	New  SyncViewModel       `json:"new"`
	Del  SyncDeleteViewModel `json:"del"`
	Date string              `json:"date"`
}

type SyncViewModel struct {
	Tracks             []view_models.TrackViewModel             `json:"tracks"`
	Albums             []view_models.AlbumViewModel             `json:"albums"`
	Artists            []view_models.ArtistViewModel            `json:"artists"`
	Playlists          []view_models.PlaylistViewModel          `json:"playlists"`
	SharedPlayedTracks []view_models.SharedPlayedTrackViewModel `json:"shared_played_tracks"`
}

type SyncDeleteViewModel struct {
	Tracks             []int `json:"tracks"`
	Albums             []int `json:"albums"`
	Artists            []int `json:"artists"`
	Playlists          []int `json:"playlists"`
	SharedPlayedTracks []int `json:"shared_played_tracks"`
}

func (p *SyncPresenter) ShowFullSync(
	ctx context.Context,
	tracks []entities.Track,
	albums []entities.Album,
	artists []entities.Artist,
	playlists []entities.Playlist,
	sharedPlayedTracks []entities.SharedPlayedTrack,

	date time.Time,
) models.APIResponse {
	return models.JsonAPIResponse{
		Data: FullSyncViewModel{
			SyncViewModel: SyncViewModel{
				Tracks:             view_models.ConvertToTrackViewModels(ctx, tracks),
				Albums:             view_models.ConvertToAlbumsViewModel(ctx, albums),
				Artists:            view_models.ConvertToArtistsViewModel(ctx, artists),
				Playlists:          view_models.ConvertToPlaylistViewModels(ctx, playlists),
				SharedPlayedTracks: view_models.ConvertToSharedPlayedTracksViewModel(sharedPlayedTracks),
			},
			Date: date.Format(time.RFC3339),
		},
	}
}

func (p *SyncPresenter) ShowPartialSync(
	ctx context.Context,
	tracks []entities.Track,
	albums []entities.Album,
	artists []entities.Artist,
	playlists []entities.Playlist,
	sharedPlayedTracks []entities.SharedPlayedTrack,

	deletedTracks []int,
	deletedAlbums []int,
	deletedArtists []int,
	deletedPlaylists []int,
	deletedSharedPlayedTracks []int,

	date time.Time,
) models.APIResponse {
	return models.JsonAPIResponse{
		Data: PartialSyncViewModel{
			New: SyncViewModel{
				Tracks:             view_models.ConvertToTrackViewModels(ctx, tracks),
				Albums:             view_models.ConvertToAlbumsViewModel(ctx, albums),
				Artists:            view_models.ConvertToArtistsViewModel(ctx, artists),
				Playlists:          view_models.ConvertToPlaylistViewModels(ctx, playlists),
				SharedPlayedTracks: view_models.ConvertToSharedPlayedTracksViewModel(sharedPlayedTracks),
			},
			Del: SyncDeleteViewModel{
				Tracks:             deletedTracks,
				Albums:             deletedAlbums,
				Artists:            deletedArtists,
				Playlists:          deletedPlaylists,
				SharedPlayedTracks: deletedSharedPlayedTracks,
			},
			Date: date.Format(time.RFC3339),
		},
	}
}
