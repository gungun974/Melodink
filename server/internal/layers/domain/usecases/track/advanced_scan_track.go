package track_usecase

import (
	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/data/scanners"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

func (u *TrackUsecase) advancedScanTrack(
	currentTrack entities.Track,
	onlyReplaceEmptyFields bool,
) (entities.Track, error) {
	newTrack := currentTrack

	acoustResult, err := u.acoustIdScanner.ScanAcoustId(currentTrack.Path)
	if err != nil {
		return entities.Track{}, err
	}

	acoustId := acoustResult.Results[0].Id

	newTrack.Metadata.AcoustID = acoustId

	if len(acoustResult.Results[0].Recordings) == 0 {
		return newTrack, nil
	}

	var musicBrainzScanResult scanners.MusicBrainzScanResult

	musicBrainzScanResult, err = u.musicBrainzScanner.FetchRecordingInfoFromRelease(
		newTrack.Metadata.MusicBrainzReleaseId,
		newTrack.Metadata.MusicBrainzRecordingId,
	)
	if err != nil {
		musicBrainzScanResult, err = u.musicBrainzScanner.FetchRecordingInfoFromAlbumName(
			acoustResult.Results[0].Recordings[0],
			currentTrack.Metadata.Album,
		)
		if err != nil {
			return entities.Track{}, err
		}
	}

	helpers.CheckAndReplaceEmptyString(
		&newTrack.Title,
		musicBrainzScanResult.Title,
		onlyReplaceEmptyFields,
	)

	helpers.CheckAndReplaceEmptyString(
		&newTrack.Metadata.Album,
		musicBrainzScanResult.Album,
		onlyReplaceEmptyFields,
	)

	helpers.CheckAndReplaceEmptyInt(
		&newTrack.Metadata.TrackNumber,
		musicBrainzScanResult.TrackNumber,
		onlyReplaceEmptyFields,
	)
	helpers.CheckAndReplaceEmptyInt(
		&newTrack.Metadata.TotalTracks,
		musicBrainzScanResult.TotalTracks,
		onlyReplaceEmptyFields,
	)

	helpers.CheckAndReplaceEmptyInt(
		&newTrack.Metadata.DiscNumber,
		musicBrainzScanResult.DiscNumber,
		onlyReplaceEmptyFields,
	)
	helpers.CheckAndReplaceEmptyInt(
		&newTrack.Metadata.TotalDiscs,
		musicBrainzScanResult.TotalDiscs,
		onlyReplaceEmptyFields,
	)

	helpers.CheckAndReplaceEmptyString(
		&newTrack.Metadata.Date,
		musicBrainzScanResult.Date,
		onlyReplaceEmptyFields,
	)
	helpers.CheckAndReplaceEmptyInt(
		&newTrack.Metadata.Year,
		musicBrainzScanResult.Year,
		onlyReplaceEmptyFields,
	)

	if (len(newTrack.Metadata.Genres) == 0 || !onlyReplaceEmptyFields) &&
		len(musicBrainzScanResult.Genres) != 0 {
		newTrack.Metadata.Genres = musicBrainzScanResult.Genres
	}

	helpers.CheckAndReplaceEmptyString(
		&newTrack.Metadata.MusicBrainzReleaseId,
		musicBrainzScanResult.MusicBrainzReleaseId,
		onlyReplaceEmptyFields,
	)
	helpers.CheckAndReplaceEmptyString(
		&newTrack.Metadata.MusicBrainzTrackId,
		musicBrainzScanResult.MusicBrainzTrackId,
		onlyReplaceEmptyFields,
	)
	helpers.CheckAndReplaceEmptyString(
		&newTrack.Metadata.MusicBrainzRecordingId,
		musicBrainzScanResult.MusicBrainzRecordingId,
		onlyReplaceEmptyFields,
	)

	if (len(newTrack.Metadata.Artists) == 0 || !onlyReplaceEmptyFields) &&
		len(musicBrainzScanResult.Artists) != 0 {
		newTrack.Metadata.Artists = musicBrainzScanResult.Artists
	}
	if (len(newTrack.Metadata.AlbumArtists) == 0 || !onlyReplaceEmptyFields) &&
		len(musicBrainzScanResult.AlbumArtists) != 0 {
		newTrack.Metadata.AlbumArtists = musicBrainzScanResult.AlbumArtists
	}

	if (len(newTrack.Metadata.ArtistsRoles) == 0 || !onlyReplaceEmptyFields) &&
		len(musicBrainzScanResult.ArtistsRoles) != 0 {
		newTrack.Metadata.ArtistsRoles = musicBrainzScanResult.ArtistsRoles
	}

	return newTrack, nil
}
