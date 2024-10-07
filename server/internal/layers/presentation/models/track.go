package view_models

import (
	"time"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type TrackViewModel struct {
	Id int `json:"id"`

	UserId *int `json:"user_id"`

	Title    string `json:"title"`
	Duration int    `json:"duration"`

	TagsFormat string `json:"tags_format"`
	FileType   string `json:"file_type"`

	Path          string `json:"path"`
	FileSignature string `json:"file_signature"`

	Metadata TrackMetadataViewModel `json:"metadata"`

	DateAdded time.Time `json:"date_added"`
}

func ConvertToTrackViewModel(
	track entities.Track,
) TrackViewModel {
	return TrackViewModel{
		Id: track.Id,

		UserId: track.UserId,

		Title:    track.Title,
		Duration: track.Duration,

		TagsFormat: track.TagsFormat,
		FileType:   track.FileType,

		Path:          track.Path,
		FileSignature: track.FileSignature,

		DateAdded: track.DateAdded,

		Metadata: ConvertToTrackMetadataViewModel(track.Metadata),
	}
}

type TrackMetadataViewModel struct {
	Album   string `json:"album"`
	AlbumId string `json:"album_id"`

	TrackNumber int `json:"track_number"`
	TotalTracks int `json:"total_tracks"`

	DiscNumber int `json:"disc_number"`
	TotalDiscs int `json:"total_discs"`

	Date string `json:"date"`
	Year int    `json:"year"`

	Genres  []string `json:"genres"`
	Lyrics  string   `json:"lyrics"`
	Comment string   `json:"comment"`

	AcoustID string `json:"acoust_id"`

	MusicBrainzReleaseId   string `json:"music_brainz_release_id"`
	MusicBrainzTrackId     string `json:"music_brainz_track_id"`
	MusicBrainzRecordingId string `json:"music_brainz_recording_id"`

	Artists      []MinimalArtistViewModel   `json:"artists"`
	AlbumArtists []MinimalArtistViewModel   `json:"album_artists"`
	ArtistsRoles []TrackArtistRoleViewModel `json:"artists_roles"`

	Composer string `json:"composer"`
}

func ConvertToTrackMetadataViewModel(
	metadata entities.TrackMetadata,
) TrackMetadataViewModel {
	albumId := ""

	if id, err := metadata.GetVirtualAlbumId(); err == nil {
		albumId = id
	}

	return TrackMetadataViewModel{
		Album:   metadata.Album,
		AlbumId: albumId,

		TrackNumber: metadata.TrackNumber,
		TotalTracks: metadata.TotalTracks,

		DiscNumber: metadata.DiscNumber,
		TotalDiscs: metadata.TotalDiscs,

		Date: metadata.Date,
		Year: metadata.Year,

		Genres:  metadata.Genres,
		Lyrics:  metadata.Lyrics,
		Comment: metadata.Comment,

		AcoustID: metadata.AcoustID,

		MusicBrainzReleaseId:   metadata.MusicBrainzReleaseId,
		MusicBrainzTrackId:     metadata.MusicBrainzTrackId,
		MusicBrainzRecordingId: metadata.MusicBrainzRecordingId,

		Artists:      ConvertToMinimalArtistsViewModel(metadata.Artists),
		AlbumArtists: ConvertToMinimalArtistsViewModel(metadata.AlbumArtists),
		ArtistsRoles: ConvertToTrackArtistsRolesViewModel(metadata.ArtistsRoles),

		Composer: metadata.Composer,
	}
}

type TrackArtistRoleViewModel struct {
	Type string `json:"type"`

	Artist string `json:"artist"`

	Attributes []string `json:"attributes"`
}

func ConvertToTrackArtistsRolesViewModel(
	artistsRoles []entities.TrackArtistRole,
) []TrackArtistRoleViewModel {
	artistsRolesViewModels := make([]TrackArtistRoleViewModel, len(artistsRoles))

	for i, artistRole := range artistsRoles {
		artistsRolesViewModels[i] = ConvertToTrackArtistRoleViewModel(artistRole)
	}

	return artistsRolesViewModels
}

func ConvertToTrackArtistRoleViewModel(
	artistRole entities.TrackArtistRole,
) TrackArtistRoleViewModel {
	return TrackArtistRoleViewModel{
		Type: artistRole.Type,

		Artist: artistRole.Artist,

		Attributes: artistRole.Attributes,
	}
}

type MinimalTrackViewModel struct {
	Id int `json:"id"`

	Title    string `json:"title"`
	Duration int    `json:"duration"`

	Album   string `json:"album"`
	AlbumId string `json:"album_id"`

	TrackNumber int `json:"track_number"`

	DiscNumber int `json:"disc_number"`

	Date string `json:"date"`
	Year int    `json:"year"`

	Genres []string `json:"genres"`

	Artists      []MinimalArtistViewModel `json:"artists"`
	AlbumArtists []MinimalArtistViewModel `json:"album_artists"`
	Composer     string                   `json:"composer"`

	DateAdded time.Time `json:"date_added"`
}

func ConvertToMinimalTrackViewModel(
	track entities.Track,
) MinimalTrackViewModel {
	albumId := ""

	if id, err := track.Metadata.GetVirtualAlbumId(); err == nil {
		albumId = id
	}

	if track.Metadata.Genres == nil {
		track.Metadata.Genres = []string{}
	}

	return MinimalTrackViewModel{
		Id: track.Id,

		Title:    track.Title,
		Duration: track.Duration,

		Album:   track.Metadata.Album,
		AlbumId: albumId,

		TrackNumber: track.Metadata.TrackNumber,

		DiscNumber: track.Metadata.DiscNumber,

		Date: track.Metadata.Date,
		Year: track.Metadata.Year,

		Genres: track.Metadata.Genres,

		Artists:      ConvertToMinimalArtistsViewModel(track.Metadata.Artists),
		AlbumArtists: ConvertToMinimalArtistsViewModel(track.Metadata.AlbumArtists),

		DateAdded: track.DateAdded,
	}
}
