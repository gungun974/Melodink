package track_usecase

import (
	"crypto/md5"
	"encoding/hex"
	"io"
	"os"
	"strings"

	"github.com/dhowden/tag"
	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/pkgs/audiolength"
)

func makeFileSignature(path string) (string, error) {
	file, err := os.Open(path)
	if err != nil {
		return "", err
	}

	defer file.Close()

	hash := md5.New()
	_, err = io.Copy(hash, file)
	if err != nil {
		return "", err
	}

	return hex.EncodeToString(hash.Sum(nil)), nil
}

func scanAudio(path string) (entities.Track, error) {
	signature, err := makeFileSignature(path)
	if err != nil {
		return entities.Track{}, err
	}

	file, err := os.Open(path)
	if err != nil {
		return entities.Track{}, err
	}
	defer file.Close()

	metadata, err := tag.ReadFrom(file)
	if err != nil {
		return entities.Track{}, err
	}

	duration, _ := audiolength.GetAudioDuration(path)

	tn, tt := metadata.Track()
	dn, td := metadata.Disc()

	rawMetadata := metadata.Raw()

	date := ""

	if data, ok := rawMetadata["date"]; ok {
		if data, ok := data.(string); ok {
			date = data
		}
	}

	acoustID := ""

	if data, ok := rawMetadata["acoustid_id"]; ok {
		if data, ok := data.(string); ok {
			acoustID = data
		}
	}

	acoustIDFingerprint := ""

	if data, ok := rawMetadata["acoustid_fingerprint"]; ok {
		if data, ok := data.(string); ok {
			acoustIDFingerprint = data
		}
	}

	copyright := ""

	if data, ok := rawMetadata["copyright"]; ok {
		if data, ok := data.(string); ok {
			copyright = data
		}
	}

	rawArtist := metadata.Artist()
	rawAlbumArtist := metadata.AlbumArtist()

	artists := strings.Split(rawArtist, ",")
	albumArtists := strings.Split(rawAlbumArtist, ",")

	for i := range artists {
		artists[i] = strings.TrimSpace(artists[i])
	}

	for i := range albumArtists {
		albumArtists[i] = strings.TrimSpace(albumArtists[i])
	}

	artists = helpers.RemoveEmptyStrings(artists)
	albumArtists = helpers.RemoveEmptyStrings(albumArtists)

	return entities.Track{
		Title:    metadata.Title(),
		Duration: duration,

		TagsFormat: string(metadata.Format()),
		FileType:   string(metadata.FileType()),

		Path:          path,
		FileSignature: signature,

		Metadata: entities.TrackMetadata{
			Album: metadata.Album(),

			TrackNumber: tn,
			TotalTracks: tt,

			DiscNumber: dn,
			TotalDiscs: td,

			Date: date,
			Year: metadata.Year(),

			Genre:   metadata.Genre(),
			Lyrics:  metadata.Lyrics(),
			Comment: metadata.Comment(),

			AcoustID:            acoustID,
			AcoustIDFingerprint: acoustIDFingerprint,

			Artists:      artists,
			AlbumArtists: albumArtists,
			Composer:     metadata.Composer(),

			Copyright: copyright,
		},
	}, nil
}
