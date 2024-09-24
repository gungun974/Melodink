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

	MetadataGenre   string `db:"metadata_genre"`
	MetadataLyrics  string `db:"metadata_lyrics"`
	MetadataComment string `db:"metadata_comment"`

	MetadataAcoustID            string `db:"metadata_acoust_id"`
	MetadataAcoustIDFingerprint string `db:"metadata_acoust_id_fingerprint"`

	MetadataArtists      string `db:"metadata_artists"`
	MetadataAlbumArtists string `db:"metadata_album_artists"`
	MetadataComposer     string `db:"metadata_composer"`

	MetadataCopyright string `db:"metadata_copyright"`

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

			Genre:   m.MetadataGenre,
			Lyrics:  m.MetadataLyrics,
			Comment: m.MetadataComment,

			AcoustID:            m.MetadataAcoustID,
			AcoustIDFingerprint: m.MetadataAcoustIDFingerprint,

			Artists:      artists,
			AlbumArtists: albumArtists,
			Composer:     m.MetadataComposer,

			Copyright: m.MetadataCopyright,
		},
	}
}
