package track_usecase

import (
	"gungun974.com/melodink-server/internal/layers/domain/entities"
	"gungun974.com/melodink-server/pb"
)

func (u *TrackUsecase) GetAllTracks() (*pb.TrackList, error) {
	tracks, err := u.trackRepository.GetAllTracks()
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	return u.trackPresenter.ShowAllTracks(tracks), nil
}
