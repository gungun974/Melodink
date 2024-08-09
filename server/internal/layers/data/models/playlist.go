package data_models

import (
	"time"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type PlaylistsModels []PlaylistModel

func (s PlaylistsModels) ToPlaylists() []entities.Playlist {
	e := make([]entities.Playlist, 0, len(s))

	for _, m := range s {
		e = append(e, m.ToPlaylist())
	}

	return e
}

type PlaylistModel struct {
	Id int `db:"id"`

	UserId *int `db:"user_id"`

	Name        string `db:"name"`
	Description string `db:"description"`

	TrackIds string `db:"track_ids"`

	CreatedAt time.Time  `db:"created_at"`
	UpdatedAt *time.Time `db:"updated_at"`
}

func (m *PlaylistModel) ToPlaylist() entities.Playlist {
	return entities.Playlist{
		Id: m.Id,

		UserId: m.UserId,

		Name:        m.Name,
		Description: m.Description,

		Tracks: []entities.Track{},
	}
}
