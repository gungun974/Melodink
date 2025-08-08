package view_models

import (
	"context"
	"time"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type TrackViewModel struct {
	Id int `json:"id"`

	UserId *int `json:"user_id"`

	Title    string `json:"title"`
	Duration int    `json:"duration"`

	TagsFormat string `json:"tags_format"`
	FileType   string `json:"file_type"`

	Path           string `json:"path"`
	FileSignature  string `json:"file_signature"`
	CoverSignature string `json:"cover_signature"`

	Metadata TrackMetadataViewModel `json:"metadata"`

	SampleRate       int  `json:"sample_rate"`
	BitRate          *int `json:"bit_rate"`
	BitsPerRawSample *int `json:"bits_per_raw_sample"`

	Score float64 `json:"score"`

	DateAdded string `json:"date_added"`
}

func ConvertToTrackViewModel(
	ctx context.Context,
	track entities.Track,
) TrackViewModel {
	return TrackViewModel{
		Id: track.Id,

		UserId: track.UserId,

		Title:    track.Title,
		Duration: track.Duration,

		TagsFormat: track.TagsFormat,
		FileType:   track.FileType,

		Path:           track.Path,
		FileSignature:  track.FileSignature,
		CoverSignature: track.CoverSignature,

		DateAdded: track.DateAdded.UTC().Format(time.RFC3339),

		Metadata: ConvertToTrackMetadataViewModel(
			track,
		),

		SampleRate:       track.SampleRate,
		BitRate:          track.BitRate,
		BitsPerRawSample: track.BitsPerRawSample,

		Score: getTrackScore(ctx, track),
	}
}

type TrackMetadataViewModel struct {
	Album   string `json:"album"`
	AlbumId int    `json:"album_id"`

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
	track entities.Track,
) TrackMetadataViewModel {
	album := ""
	albumId := 0
	albumArtists := []entities.Artist{}

	metadata := track.Metadata

	if len(track.Albums) != 0 {
		album = track.Albums[0].Name
		albumId = track.Albums[0].Id
		albumArtists = track.Albums[0].Artists
	}

	if metadata.Genres == nil {
		metadata.Genres = []string{}
	}

	return TrackMetadataViewModel{
		Album:   album,
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

		Artists:      ConvertToMinimalArtistsViewModel(track.Artists),
		AlbumArtists: ConvertToMinimalArtistsViewModel(albumArtists),
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
	AlbumId int    `json:"album_id"`

	TrackNumber int `json:"track_number"`

	DiscNumber int `json:"disc_number"`

	Date string `json:"date"`
	Year int    `json:"year"`

	Genres []string `json:"genres"`

	Artists      []MinimalArtistViewModel `json:"artists"`
	AlbumArtists []MinimalArtistViewModel `json:"album_artists"`
	Composer     string                   `json:"composer"`

	FileType string `json:"file_type"`

	FileSignature string `json:"file_signature"`

	SampleRate       int  `json:"sample_rate"`
	BitRate          *int `json:"bit_rate"`
	BitsPerRawSample *int `json:"bits_per_raw_sample"`

	Score float64 `json:"score"`

	DateAdded string `json:"date_added"`
}

func ConvertToMinimalTrackViewModel(
	ctx context.Context,
	track entities.Track,
) MinimalTrackViewModel {
	album := ""
	albumId := 0
	albumArtists := []entities.Artist{}

	if len(track.Albums) != 0 {
		album = track.Albums[0].Name
		albumId = track.Albums[0].Id
		albumArtists = track.Albums[0].Artists
	}

	if track.Metadata.Genres == nil {
		track.Metadata.Genres = []string{}
	}

	return MinimalTrackViewModel{
		Id: track.Id,

		Title:    track.Title,
		Duration: track.Duration,

		Album:   album,
		AlbumId: albumId,

		TrackNumber: track.Metadata.TrackNumber,

		DiscNumber: track.Metadata.DiscNumber,

		Date: track.Metadata.Date,
		Year: track.Metadata.Year,

		Genres: track.Metadata.Genres,

		Artists:      ConvertToMinimalArtistsViewModel(track.Artists),
		AlbumArtists: ConvertToMinimalArtistsViewModel(albumArtists),

		FileType: track.FileType,

		FileSignature: track.FileSignature,

		SampleRate:       track.SampleRate,
		BitRate:          track.BitRate,
		BitsPerRawSample: track.BitsPerRawSample,

		Score: getTrackScore(ctx, track),

		DateAdded: track.DateAdded.UTC().Format(time.RFC3339),
	}
}

func getTrackScore(
	ctx context.Context,
	track entities.Track,
) float64 {
	if len(track.Scores) != 0 {
		user, err := helpers.ExtractCurrentLoggedUser(ctx)
		if err == nil {
			for _, trackScore := range track.Scores {
				if trackScore.UserId == user.Id {
					return trackScore.Score
				}
			}
		}
	}

	return 0.0
}
