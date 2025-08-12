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

	FileSignature  string `json:"file_signature"`
	CoverSignature string `json:"cover_signature"`

	Albums  []int `json:"albums"`
	Artists []int `json:"artists"`

	TrackNumber int `json:"track_number"`
	DiscNumber  int `json:"disc_number"`

	Metadata TrackMetadataViewModel `json:"metadata"`

	SampleRate       int  `json:"sample_rate"`
	BitRate          *int `json:"bit_rate"`
	BitsPerRawSample *int `json:"bits_per_raw_sample"`

	Score float64 `json:"score"`

	DateAdded string `json:"date_added"`
}

type TrackMetadataViewModel struct {
	TotalTracks int `json:"total_tracks"`
	TotalDiscs  int `json:"total_discs"`

	Date string `json:"date"`
	Year int    `json:"year"`

	Genres  []string `json:"genres"`
	Lyrics  string   `json:"lyrics"`
	Comment string   `json:"comment"`

	AcoustID string `json:"acoust_id"`

	MusicBrainzReleaseId   string `json:"music_brainz_release_id"`
	MusicBrainzTrackId     string `json:"music_brainz_track_id"`
	MusicBrainzRecordingId string `json:"music_brainz_recording_id"`

	Composer string `json:"composer"`
}

func ConvertToTrackViewModels(
	ctx context.Context,
	tracks []entities.Track,
) []TrackViewModel {
	tracksViewModels := make([]TrackViewModel, len(tracks))

	for i, track := range tracks {
		tracksViewModels[i] = ConvertToTrackViewModel(ctx, track)
	}

	return tracksViewModels
}

func ConvertToTrackViewModel(
	ctx context.Context,
	track entities.Track,
) TrackViewModel {
	albums := make([]int, len(track.Albums))

	for i, album := range track.Albums {
		albums[i] = album.Id
	}

	artists := make([]int, len(track.Artists))

	for i, artist := range track.Artists {
		artists[i] = artist.Id
	}

	metadata := track.Metadata

	if metadata.Genres == nil {
		metadata.Genres = []string{}
	}

	return TrackViewModel{
		Id: track.Id,

		UserId: track.UserId,

		Title:    track.Title,
		Duration: track.Duration,

		TagsFormat: track.TagsFormat,
		FileType:   track.FileType,

		FileSignature:  track.FileSignature,
		CoverSignature: track.CoverSignature,

		DateAdded: track.DateAdded.UTC().Format(time.RFC3339),

		Albums:  albums,
		Artists: artists,

		TrackNumber: metadata.TrackNumber,
		DiscNumber:  metadata.DiscNumber,

		Metadata: TrackMetadataViewModel{
			TotalTracks: metadata.TotalTracks,
			TotalDiscs:  metadata.TotalDiscs,

			Date: metadata.Date,
			Year: metadata.Year,

			Genres:  metadata.Genres,
			Lyrics:  metadata.Lyrics,
			Comment: metadata.Comment,

			AcoustID: metadata.AcoustID,

			MusicBrainzReleaseId:   metadata.MusicBrainzReleaseId,
			MusicBrainzTrackId:     metadata.MusicBrainzTrackId,
			MusicBrainzRecordingId: metadata.MusicBrainzRecordingId,

			Composer: metadata.Composer,
		},

		SampleRate:       track.SampleRate,
		BitRate:          track.BitRate,
		BitsPerRawSample: track.BitsPerRawSample,

		Score: getTrackScore(ctx, track),
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
