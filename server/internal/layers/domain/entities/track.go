package entities

import (
	"crypto/md5"
	"encoding/hex"
	"errors"
	"slices"
	"strings"
	"time"
)

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

	SampleRate       int
	BitRate          *int
	BitsPerRawSample *int

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

func (m TrackMetadata) GetVirtualAlbumArtists() []string {
	artists := slices.Clone(m.AlbumArtists)

	if len(artists) == 0 && len(m.Artists) > 0 {
		artists = []string{m.Artists[0]}
	}

	slices.Sort(artists)

	return artists
}

func (m TrackMetadata) GetVirtualAlbumId() (string, error) {
	if len(strings.TrimSpace(m.Album)) == 0 {
		return "", errors.New("This track has no album")
	}

	rawId := "a#" + strings.ReplaceAll(
		m.Album,
		"#",
		"##",
	) + "r#" + strings.ReplaceAll(
		strings.Join(m.GetVirtualAlbumArtists(), "$"),
		"#",
		"##",
	)

	hasher := md5.New()

	hasher.Write([]byte(rawId))

	hashBytes := hasher.Sum(nil)

	hashString := hex.EncodeToString(hashBytes)

	return hashString, nil
}
