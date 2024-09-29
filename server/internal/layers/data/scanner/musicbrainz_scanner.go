package scanner

import (
	"errors"
	"sync"
	"time"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"go.uploadedlobster.com/musicbrainzws2"
)

func NewMusicBrainzScanner() MusicBrainzScanner {
	return MusicBrainzScanner{
		mutex: sync.Mutex{},
	}
}

type MusicBrainzScanner struct {
	mutex sync.Mutex
}

type MusicBrainzScanResult struct {
	Title string

	Album string

	TrackNumber int
	TotalTracks int

	DiscNumber int
	TotalDiscs int

	Date string
	Year int

	Genres []string

	MusicBrainzReleaseId   string
	MusicBrainzTrackId     string
	MusicBrainzRecordingId string

	Artists      []string
	AlbumArtists []string

	ArtistsRoles []entities.TrackArtistRole

	Composer string
}

func (s *MusicBrainzScanner) FetchRecordingInfoFromAlbumName(
	acoustIdRecording AcoustIdRecording,
	currentAlbum string,
) (MusicBrainzScanResult, error) {
	if len(acoustIdRecording.Releases) == 0 {
		return MusicBrainzScanResult{}, nil
	}

	var selectedReleaseId string

	for _, release := range acoustIdRecording.Releases {
		if release.Title == currentAlbum {
			selectedReleaseId = release.Id
			break
		}
	}

	if selectedReleaseId == "" {
		selectedReleaseId = acoustIdRecording.Releases[0].Id
	}

	return s.FetchRecordingInfoFromRelease(acoustIdRecording.Id, selectedReleaseId)
}

var (
	MusicBrainzReleaseNotFoundError   = errors.New("MusicBrainz Release is not found")
	MusicBrainzTrackNotFoundError     = errors.New("MusicBrainz Track is not found")
	MusicBrainzRecordingNotFoundError = errors.New("MusicBrainz Recording is not found")
)

func (s *MusicBrainzScanner) FetchRecordingInfoFromRelease(
	recordingId string,
	releaseId string,
) (MusicBrainzScanResult, error) {
	if helpers.IsEmptyOrWhitespace(recordingId) {
		return MusicBrainzScanResult{}, MusicBrainzRecordingNotFoundError
	}
	if helpers.IsEmptyOrWhitespace(releaseId) {
		return MusicBrainzScanResult{}, MusicBrainzReleaseNotFoundError
	}

	client := musicbrainzws2.NewClient("melodink", "0.1 ( https://github.com/gungun974/Melodink )")

	releaseFilter := musicbrainzws2.IncludesFilter{
		Includes: []string{
			"media",
			"recordings",
			"artist-credits",
			"genres",
		},
	}

	s.mutex.Lock()

	logger.ScannerLogger.Infof("Perform a musicbrainz lookup for release %s", releaseId)

	release, err := client.LookupRelease(musicbrainzws2.MBID(releaseId), releaseFilter)
	if err != nil {
		logger.ScannerLogger.Errorf(
			"Failed to perform a musicbrainz lookup for release %s, %v",
			releaseId,
			err,
		)

		time.Sleep(time.Millisecond * 1100)
		s.mutex.Unlock()

		return MusicBrainzScanResult{}, MusicBrainzReleaseNotFoundError
	}

	time.Sleep(time.Millisecond * 1100)
	s.mutex.Unlock()

	var track *musicbrainzws2.Track
	var media musicbrainzws2.Medium

outerloop:
	for _, lmedia := range release.Media {
		for _, ltrack := range lmedia.Tracks {
			if ltrack.Recording.ID == musicbrainzws2.MBID(recordingId) {
				track = &ltrack
				media = lmedia
				break outerloop
			}
		}
	}

	if track == nil {
		return MusicBrainzScanResult{}, MusicBrainzTrackNotFoundError
	}

	if media.Format == "DVD" {
	outerloop2:
		for _, lmedia := range release.Media {
			if lmedia.Format == "DVD" {
				continue
			}
			for _, ltrack := range lmedia.Tracks {
				if ltrack.Title == track.Title {
					track = &ltrack
					media = lmedia
					break outerloop2
				}
			}
		}
	}

	artists := []string{}

	for _, artist := range track.Recording.ArtistCredit {
		artists = append(artists, artist.Name)
	}

	albumArtists := []string{}

	for _, artist := range release.ArtistCredit {
		albumArtists = append(albumArtists, artist.Name)
	}

	genres := []string{}

	for _, genre := range track.Recording.Genres {
		genres = append(albumArtists, genre.Name)
	}

	recordingFilter := musicbrainzws2.IncludesFilter{
		Includes: []string{
			"area-rels",
			"artist-rels",
			"event-rels",
			"instrument-rels",
			"label-rels",
			"place-rels",
			"recording-rels",
			"release-rels",
			"release-group-rels",
			"series-rels",
			"url-rels",
			"work-rels",
		},
	}

	s.mutex.Lock()

	logger.ScannerLogger.Infof("Perform a musicbrainz lookup for recording %s", track.Recording.ID)

	recordingWithRelation, err := client.LookupRecording(track.Recording.ID, recordingFilter)
	if err != nil {
		logger.ScannerLogger.Errorf(
			"Failed to perform a musicbrainz lookup for recording %s, %v",
			track.Recording.ID,
			err,
		)

		time.Sleep(time.Millisecond * 1100)
		s.mutex.Unlock()

		return MusicBrainzScanResult{}, MusicBrainzRecordingNotFoundError
	}

	time.Sleep(time.Millisecond * 1100)
	s.mutex.Unlock()

	artistsRoles := []entities.TrackArtistRole{}

	for _, relation := range recordingWithRelation.Relations {
		if relation.Artist != nil {

			attributes := make([]string, 0, len(relation.AttributeIDs))

			for _, id := range relation.AttributeIDs {
				attributes = append(attributes, string(id))
			}

			artistsRoles = append(artistsRoles, entities.TrackArtistRole{
				Type: string(relation.TypeID),

				Artist: relation.Artist.Name,

				Attributes: attributes,
			})
		}
	}

	return MusicBrainzScanResult{
		Title: track.Title,

		Album: release.Title,

		TrackNumber: track.Position,
		TotalTracks: media.TrackCount,

		DiscNumber: media.Position,
		TotalDiscs: len(release.Media),

		Date: release.Date.String(),
		Year: release.Date.Year,

		Genres: genres,

		MusicBrainzReleaseId:   string(release.ID),
		MusicBrainzTrackId:     string(track.ID),
		MusicBrainzRecordingId: string(track.Recording.ID),

		Artists:      artists,
		AlbumArtists: albumArtists,
		ArtistsRoles: artistsRoles,
	}, nil
}
