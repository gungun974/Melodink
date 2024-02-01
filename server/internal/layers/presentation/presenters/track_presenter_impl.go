package presenter_impl

import (
	"google.golang.org/protobuf/types/known/timestamppb"
	"gungun974.com/melodink-server/internal/layers/domain/entities"
	presenter "gungun974.com/melodink-server/internal/layers/domain/presenters"
	"gungun974.com/melodink-server/pb"
)

type TrackPresenterImpl struct{}

func NewTrackPresenterImpl() presenter.TrackPresenter {
	return &TrackPresenterImpl{}
}

func (p *TrackPresenterImpl) ShowAllTracks(
	tracks []entities.Track,
) *pb.TrackList {
	pbTracks := make([]*pb.Track, len(tracks))

	for i, track := range tracks {
		pbTracks[i] = p.ShowTrack(track)
	}

	return &pb.TrackList{
		Tracks: pbTracks,
	}
}

func (p *TrackPresenterImpl) ShowTrack(
	track entities.Track,
) *pb.Track {
	return &pb.Track{
		Id: int32(track.Id),

		Title:    track.Title,
		Album:    track.Album,
		Duration: int32(track.Duration),

		TagsFormat: track.TagsFormat,
		FileType:   track.FileType,

		Path:          track.Path,
		FileSignature: track.FileSignature,

		DateAdded: timestamppb.New(track.DateAdded),

		Metadata: &pb.TrackMetadata{
			TrackNumber: int32(track.Metadata.TrackNumber),
			TotalTracks: int32(track.Metadata.TotalTracks),

			DiscNumber: int32(track.Metadata.DiscNumber),
			TotalDiscs: int32(track.Metadata.TotalDiscs),

			Date: track.Metadata.Date,
			Year: int32(track.Metadata.Year),

			Genre:   track.Metadata.Genre,
			Lyrics:  track.Metadata.Lyrics,
			Comment: track.Metadata.Comment,

			AcoustId:            track.Metadata.AcoustID,
			AcoustIdFingerprint: track.Metadata.AcoustIDFingerprint,

			Artist:      track.Metadata.Artist,
			AlbumArtist: track.Metadata.AlbumArtist,
			Composer:    track.Metadata.Composer,

			Copyright: track.Metadata.Copyright,
		},
	}
}
