package entities

import "time"

type Track struct {
	Id int

	UserId *int

	Title    string
	Duration int

	TagsFormat string
	FileType   string

	Path          string
	FileSignature string

	Metadata TrackMetadata

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

	Genre   string
	Lyrics  string
	Comment string

	AcoustID            string
	AcoustIDFingerprint string

	Artist      string
	AlbumArtist string
	Composer    string

	Copyright string
}

func (m TrackMetadata) GetVirtualAlbumArtist() string {
	artist := m.AlbumArtist

	if len(artist) != 0 {
		return artist
	}

	return m.Artist
}
