package track_usecase

import (
	"crypto/md5"
	"encoding/hex"
	"errors"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/dhowden/tag"
	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/pkgs/audiolength"
	"github.com/gungun974/Melodink/server/pkgs/audioquality"
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
	file, err := os.Open(path)
	if err != nil {
		return entities.Track{}, err
	}
	defer file.Close()

	metadata, err := tag.ReadFrom(file)

	if errors.Is(err, tag.ErrNoTagsFound) {
		track := entities.Track{
			Title: filepath.Base(path),

			Path: path,
		}

		err = scanAudioFeature(&track)
		if err != nil {
			return entities.Track{}, err
		}

		return track, nil
	}

	if err != nil {
		return entities.Track{}, err
	}

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

	musicBrainzReleaseId := ""

	if data, ok := rawMetadata["musicbrainz_albumid"]; ok {
		if data, ok := data.(string); ok {
			musicBrainzReleaseId = data
		}
	}

	musicBrainzTrackId := ""

	if data, ok := rawMetadata["musicbrainz_trackid"]; ok {
		if data, ok := data.(string); ok {
			musicBrainzTrackId = data
		}
	}

	musicBrainzRecordingId := ""

	if data, ok := rawMetadata["musicbrainz_recordingid"]; ok {
		if data, ok := data.(string); ok {
			musicBrainzRecordingId = data
		}
	}

	rawArtist := metadata.Artist()
	rawAlbumArtist := metadata.AlbumArtist()
	rawGenres := metadata.Genre()

	artists := strings.Split(rawArtist, ",")
	albumArtists := strings.Split(rawAlbumArtist, ",")
	genres := strings.Split(rawGenres, ",")

	for i := range artists {
		artists[i] = strings.TrimSpace(artists[i])
	}

	for i := range albumArtists {
		albumArtists[i] = strings.TrimSpace(albumArtists[i])
	}

	for i := range genres {
		genres[i] = strings.TrimSpace(genres[i])
	}

	artists = helpers.RemoveEmptyStrings(artists)
	albumArtists = helpers.RemoveEmptyStrings(albumArtists)
	genres = helpers.RemoveEmptyStrings(genres)

	track := entities.Track{
		Title: metadata.Title(),

		Path: path,

		Metadata: entities.TrackMetadata{
			Album: metadata.Album(),

			TrackNumber: tn,
			TotalTracks: tt,

			DiscNumber: dn,
			TotalDiscs: td,

			Date: date,
			Year: metadata.Year(),

			Genres:  genres,
			Lyrics:  metadata.Lyrics(),
			Comment: metadata.Comment(),

			AcoustID: acoustID,

			MusicBrainzReleaseId:   musicBrainzReleaseId,
			MusicBrainzTrackId:     musicBrainzTrackId,
			MusicBrainzRecordingId: musicBrainzRecordingId,

			Artists:      artists,
			AlbumArtists: albumArtists,
			Composer:     metadata.Composer(),
		},
	}

	err = scanAudioFeature(&track)
	if err != nil {
		return entities.Track{}, err
	}

	return track, nil
}

func scanAudioFeature(track *entities.Track) error {
	signature, err := makeFileSignature(track.Path)
	if err != nil {
		return err
	}

	file, err := os.Open(track.Path)
	if err != nil {
		return err
	}
	defer file.Close()

	duration, _ := audiolength.GetAudioDuration(track.Path)

	quality, err := audioquality.GetAudioQuality(track.Path)
	if err != nil {
		logger.MainLogger.Warn(err)
	}

	track.Duration = duration

	metadata, err := tag.ReadFrom(file)

	if err != nil && !errors.Is(err, tag.ErrNoTagsFound) {
		return err
	}

	if err == nil {
		track.TagsFormat = string(metadata.Format())
		track.FileType = string(metadata.FileType())
	}

	track.FileSignature = signature

	track.SampleRate = quality.SampleRate
	track.BitRate = quality.BitRate
	track.BitsPerRawSample = quality.BitsPerRawSample

	return nil
}
