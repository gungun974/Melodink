package view_models

import (
	"time"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type TrackViewModel struct {
	Id int `json:"id"`

	UserId *int `json:"user_id"`

	Title    string `json:"title"`
	Duration int    `json:"duration"`

	TagsFormat string `json:"tags_format"`
	FileType   string `json:"file_type"`

	Path          string `json:"path"`
	FileSignature string `json:"file_signature"`

	Metadata TrackMetadataViewModel `json:"metadata"`

	DateAdded time.Time `json:"date_added"`
}

func ConvertToTrackViewModel(
	track entities.Track,
) TrackViewModel {
	return TrackViewModel{
		Id: track.Id,

		UserId: track.UserId,

		Title:    track.Title,
		Duration: track.Duration,

		TagsFormat: track.TagsFormat,
		FileType:   track.FileType,

		Path:          track.Path,
		FileSignature: track.FileSignature,

		DateAdded: track.DateAdded,

		Metadata: ConvertToTrackMetadataViewModel(track.Metadata),
	}
}

type TrackMetadataViewModel struct {
	Album string `json:"album"`

	TrackNumber int `json:"track_number"`
	TotalTracks int `json:"total_tracks"`

	DiscNumber int `json:"disc_number"`
	TotalDiscs int `json:"total_discs"`

	Date string `json:"date"`
	Year int    `json:"year"`

	Genre   string `json:"genre"`
	Lyrics  string `json:"lyrics"`
	Comment string `json:"comment"`

	AcoustID            string `json:"acoust_id"`
	AcoustIDFingerprint string `json:"acoust_id_fingerprint"`

	Artist      string `json:"artist"`
	AlbumArtist string `json:"album_artist"`
	Composer    string `json:"composer"`

	Copyright string `json:"copyright"`
}

func ConvertToTrackMetadataViewModel(
	metadata entities.TrackMetadata,
) TrackMetadataViewModel {
	return TrackMetadataViewModel{
		Album: metadata.Album,

		TrackNumber: metadata.TrackNumber,
		TotalTracks: metadata.TotalTracks,

		DiscNumber: metadata.DiscNumber,
		TotalDiscs: metadata.TotalDiscs,

		Date: metadata.Date,
		Year: metadata.Year,

		Genre:   metadata.Genre,
		Lyrics:  metadata.Lyrics,
		Comment: metadata.Comment,

		AcoustID:            metadata.AcoustID,
		AcoustIDFingerprint: metadata.AcoustIDFingerprint,

		Artist:      metadata.Artist,
		AlbumArtist: metadata.AlbumArtist,
		Composer:    metadata.Composer,

		Copyright: metadata.Copyright,
	}
}

type MinimalTrackViewModel struct {
	Id int `json:"id"`

	Title    string `json:"title"`
	Duration int    `json:"duration"`

	Album string `json:"album"`

	TrackNumber int `json:"track_number"`

	DiscNumber int `json:"disc_number"`

	Date string `json:"date"`
	Year int    `json:"year"`

	Genre string `json:"genre"`

	Artist      string `json:"artist"`
	AlbumArtist string `json:"album_artist"`
	Composer    string `json:"composer"`

	DateAdded time.Time `json:"date_added"`
}

func ConvertToMinimalTrackViewModel(
	track entities.Track,
) MinimalTrackViewModel {
	return MinimalTrackViewModel{
		Id: track.Id,

		Title:    track.Title,
		Duration: track.Duration,

		Album: track.Metadata.Album,

		TrackNumber: track.Metadata.TrackNumber,

		DiscNumber: track.Metadata.DiscNumber,

		Date: track.Metadata.Date,
		Year: track.Metadata.Year,

		Genre: track.Metadata.Genre,

		Artist:      track.Metadata.Artist,
		AlbumArtist: track.Metadata.AlbumArtist,

		DateAdded: track.DateAdded,
	}
}
