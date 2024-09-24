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

	Artists      []string
	AlbumArtists []string
	Composer     string

	Copyright string
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
