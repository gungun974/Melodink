package entities

type Track struct {
	Id int

	Title    string
	Album    string
	Duration int

	TagsFormat string
	FileType   string

	Path          string
	FileSignature string

	Metadata TrackMetadata
}

type TrackMetadata struct {
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
