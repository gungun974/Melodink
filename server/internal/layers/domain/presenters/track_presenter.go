package presenter

import (
	"gungun974.com/melodink-server/internal/layers/domain/entities"
	"gungun974.com/melodink-server/internal/models"
)

type TrackPresenter interface {
	ShowAllTracks(tracks []entities.Track) models.APIResponse
}
