package presenter

import (
	"gungun974.com/melodink-server/internal/layers/domain/entities"
	"gungun974.com/melodink-server/pb"
)

type TrackPresenter interface {
	ShowAllTracks(tracks []entities.Track) *pb.TrackList
}
