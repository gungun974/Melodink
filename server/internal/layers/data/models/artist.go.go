package data_models

import (
	"time"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type ArtistModels []ArtistModel

func (s ArtistModels) ToArtists() []entities.Artist {
	e := make([]entities.Artist, 0, len(s))

	for _, m := range s {
		e = append(e, m.ToArtist())
	}

	return e
}

type ArtistModel struct {
	Id int `db:"id"`

	Name string `db:"name"`

	UserId *int `db:"user_id"`

	CreatedAt time.Time  `db:"created_at"`
	UpdatedAt *time.Time `db:"updated_at"`
}

func (m *ArtistModel) ToArtist() entities.Artist {
	return entities.Artist{
		Id:   m.Id,
		Name: m.Name,

		UserId: m.UserId,

		Albums:        []entities.Album{},
		AppearAlbums:  []entities.Album{},
		HasRoleAlbums: []entities.Album{},

		AllTracks:        []entities.Track{},
		AllAppearTracks:  []entities.Track{},
		AllHasRoleTracks: []entities.Track{},
	}
}
