package view_models

import (
	"time"

	"gungun974.com/melodink-server/internal/layers/domain/entities"
)

type TrackJson struct {
	Id int `json:"id"`

	Title    string `json:"title"`
	Album    string `json:"album"`
	Duration int    `json:"duration"`

	TagsFormat string `json:"tags_format"`
	FileType   string `json:"file_type"`

	Path          string `json:"path"`
	FileSignature string `json:"file_signature"`

	Metadata TrackMetadataJson `json:"metadata"`

	DateAdded time.Time `json:"date_added"`
}

func ConvertToTrackJson(
	track entities.Track,
) TrackJson {
	return TrackJson{
		Id: track.Id,

		Title:    track.Title,
		Album:    track.Album,
		Duration: track.Duration,

		TagsFormat: track.TagsFormat,
		FileType:   track.FileType,

		Path:          track.Path,
		FileSignature: track.FileSignature,

		DateAdded: track.DateAdded,

		Metadata: ConvertToTrackMetadataJson(track.Metadata),
	}
}

type TrackMetadataJson struct {
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

func ConvertToTrackMetadataJson(
	metadata entities.TrackMetadata,
) TrackMetadataJson {
	return TrackMetadataJson{
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
