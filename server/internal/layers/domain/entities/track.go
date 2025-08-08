package entities

import (
	"time"
)

type Track struct {
	Id int

	UserId *int

	Title    string
	Duration int

	TagsFormat string
	FileType   string

	Path           string
	FileSignature  string
	CoverSignature string

	TranscodingLowSignature    string
	TranscodingMediumSignature string
	TranscodingHighSignature   string

	Albums  []Album
	Artists []Artist

	Metadata TrackMetadata

	SampleRate       int
	BitRate          *int
	BitsPerRawSample *int

	Scores []TrackScore

	PendingImport bool

	DateAdded time.Time
}

type TrackMetadata struct {
	Album string

	TrackNumber int
	TotalTracks int

	DiscNumber int
	TotalDiscs int

	Date string
	Year int

	Genres  []string
	Lyrics  string
	Comment string

	AcoustID string

	MusicBrainzReleaseId   string
	MusicBrainzTrackId     string
	MusicBrainzRecordingId string

	Artists      []string
	AlbumArtists []string

	ArtistsRoles []TrackArtistRole

	Composer string
}

type TrackArtistRole struct {
	Type string

	Artist string

	Attributes []string
}

type TrackScore struct {
	TrackId int
	UserId  int

	Score float64
}
