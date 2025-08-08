package data_models

import (
	"time"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type AlbumModels []AlbumModel

func (s AlbumModels) ToAlbums() []entities.Album {
	e := make([]entities.Album, 0, len(s))

	for _, m := range s {
		e = append(e, m.ToAlbum())
	}

	return e
}

type AlbumModel struct {
	Id int `db:"id"`

	Name string `db:"name"`

	UserId *int `db:"user_id"`

	CreatedAt time.Time  `db:"created_at"`
	UpdatedAt *time.Time `db:"updated_at"`
}

func (m *AlbumModel) ToAlbum() entities.Album {
	return entities.Album{
		Id:      m.Id,
		Name:    m.Name,
		UserId:  m.UserId,
		Artists: []entities.Artist{},
		Tracks:  []entities.Track{},
	}
}
