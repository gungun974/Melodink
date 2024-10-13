package data_models

import (
	"encoding/json"
	"time"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type TracksModels []TrackModel

func (s TracksModels) ToTracks() []entities.Track {
	e := make([]entities.Track, 0, len(s))

	for _, m := range s {
		e = append(e, m.ToTrack())
	}

	return e
}

type TrackModel struct {
	Id int `db:"id"`

	UserId *int `db:"user_id"`

	Title    string `db:"title"`
	Duration int    `db:"duration"`

	TagsFormat string `db:"tags_format"`
	FileType   string `db:"file_type"`

	Path          string `db:"path"`
	FileSignature string `db:"file_signature"`

	MetadataAlbum string `db:"metadata_album"`

	MetadataTrackNumber int `db:"metadata_track_number"`
	MetadataTotalTracks int `db:"metadata_total_tracks"`

	MetadataDiscNumber int `db:"metadata_disc_number"`
	MetadataTotalDiscs int `db:"metadata_total_discs"`

	MetadataDate string `db:"metadata_date"`
	MetadataYear int    `db:"metadata_year"`

	MetadataGenres  string `db:"metadata_genres"`
	MetadataLyrics  string `db:"metadata_lyrics"`
	MetadataComment string `db:"metadata_comment"`

	MetadataAcoustID string `db:"metadata_acoust_id"`

	MetadataMusicBrainzReleaseId   string `db:"metadata_music_brainz_release_id"`
	MetadataMusicBrainzTrackId     string `db:"metadata_music_brainz_track_id"`
	MetadataMusicBrainzRecordingId string `db:"metadata_music_brainz_recording_id"`

	MetadataArtists      string `db:"metadata_artists"`
	MetadataAlbumArtists string `db:"metadata_album_artists"`

	MetadataArtistsRoles string `db:"metadata_artists_roles"`

	MetadataComposer string `db:"metadata_composer"`

	SampleRate       int  `db:"sample_rate"`
	BitRate          *int `db:"bit_rate"`
	BitsPerRawSample *int `db:"bits_per_raw_sample"`

	CreatedAt time.Time  `db:"created_at"`
	UpdatedAt *time.Time `db:"updated_at"`
}

func (m *TrackModel) ToTrack() entities.Track {
	var artists []string

	if err := json.Unmarshal([]byte(m.MetadataArtists), &artists); err != nil {
		artists = []string{}
	}

	var albumArtists []string

	if err := json.Unmarshal([]byte(m.MetadataAlbumArtists), &albumArtists); err != nil {
		albumArtists = []string{}
	}

	var genres []string

	if err := json.Unmarshal([]byte(m.MetadataGenres), &genres); err != nil {
		genres = []string{}
	}

	var artistsRoles TrackArtistRoleModels

	if err := json.Unmarshal([]byte(m.MetadataArtistsRoles), &artistsRoles); err != nil {
		artistsRoles = TrackArtistRoleModels{}
	}

	return entities.Track{
		Id: m.Id,

		UserId: m.UserId,

		Title:    m.Title,
		Duration: m.Duration,

		TagsFormat: m.TagsFormat,
		FileType:   m.FileType,

		Path:          m.Path,
		FileSignature: m.FileSignature,

		DateAdded: m.CreatedAt,

		Metadata: entities.TrackMetadata{
			Album: m.MetadataAlbum,

			TrackNumber: m.MetadataTrackNumber,
			TotalTracks: m.MetadataTotalTracks,

			DiscNumber: m.MetadataDiscNumber,
			TotalDiscs: m.MetadataTotalDiscs,

			Date: m.MetadataDate,
			Year: m.MetadataYear,

			Genres:  genres,
			Lyrics:  m.MetadataLyrics,
			Comment: m.MetadataComment,

			AcoustID: m.MetadataAcoustID,

			MusicBrainzReleaseId:   m.MetadataMusicBrainzReleaseId,
			MusicBrainzTrackId:     m.MetadataMusicBrainzTrackId,
			MusicBrainzRecordingId: m.MetadataMusicBrainzRecordingId,

			Artists:      artists,
			AlbumArtists: albumArtists,

			ArtistsRoles: artistsRoles.ToTrackArtistRoles(),

			Composer: m.MetadataComposer,
		},

		SampleRate:       m.SampleRate,
		BitRate:          m.BitRate,
		BitsPerRawSample: m.BitsPerRawSample,
	}
}

type TrackArtistRoleModels []TrackArtistRoleModel

func (s TrackArtistRoleModels) ToTrackArtistRoles() []entities.TrackArtistRole {
	e := make([]entities.TrackArtistRole, 0, len(s))

	for _, m := range s {
		e = append(e, m.ToTrackArtistRole())
	}

	return e
}

func TrackArtistRoleModelsFromEntities(
	artistsRoles []entities.TrackArtistRole,
) TrackArtistRoleModels {
	m := make(TrackArtistRoleModels, 0, len(artistsRoles))

	for _, e := range artistsRoles {
		m = append(m, TrackArtistRoleModelFromEntity(e))
	}

	return m
}

type TrackArtistRoleModel struct {
	Type string `json:"type"`

	Artist string `json:"artist"`

	Attributes []string `json:"attributes"`
}

func (m *TrackArtistRoleModel) ToTrackArtistRole() entities.TrackArtistRole {
	return entities.TrackArtistRole{
		Type: m.Type,

		Artist: m.Artist,

		Attributes: m.Attributes,
	}
}

func TrackArtistRoleModelFromEntity(artistRole entities.TrackArtistRole) TrackArtistRoleModel {
	return TrackArtistRoleModel{
		Type: artistRole.Type,

		Artist: artistRole.Artist,

		Attributes: artistRole.Attributes,
	}
}
