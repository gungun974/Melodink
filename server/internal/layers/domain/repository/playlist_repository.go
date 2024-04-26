package repository

import (
	"errors"

	"gungun974.com/melodink-server/internal/layers/domain/entities"
)

var PlaylistNotFoundError = errors.New("Playlist is not found")

type PlaylistRepository interface {
	GetAllAlbums() ([]entities.Playlist, error)

	GetAlbumById(id string) (entities.Playlist, error)
}
