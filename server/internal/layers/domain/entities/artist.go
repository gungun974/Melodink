package entities

import (
	"crypto/md5"
	"encoding/hex"
	"errors"
	"strings"
)

type Artist struct {
	Id string

	UserId *int

	Name string

	Albums        []Album
	AppearAlbums  []Album
	HasRoleAlbums []Album

	AllTracks        []Track
	AllAppearTracks  []Track
	AllHasRoleTracks []Track
}

func GenerateArtistId(artist string) (string, error) {
	if len(artist) == 0 {
		return "", errors.New("This track has no artist or album artist")
	}

	rawId := "r#" + strings.ReplaceAll(
		artist,
		"#",
		"##",
	)

	hasher := md5.New()

	hasher.Write([]byte(rawId))

	hashBytes := hasher.Sum(nil)

	hashString := hex.EncodeToString(hashBytes)

	return hashString, nil
}
