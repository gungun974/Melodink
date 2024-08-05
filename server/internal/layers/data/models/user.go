package data_models

import (
	"time"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

type UserModels []UserModel

func (s UserModels) ToUsers() []entities.User {
	e := make([]entities.User, 0, len(s))

	for _, m := range s {
		e = append(e, m.ToUser())
	}

	return e
}

type UserModel struct {
	Id int `db:"id"`

	Name  string `db:"name"`
	Email string `db:"email"`

	Password *string `db:"password"`

	CreatedAt time.Time  `db:"created_at"`
	UpdatedAt *time.Time `db:"updated_at"`
}

func (m *UserModel) ToUser() entities.User {
	password := ""

	if m.Password != nil {
		password = *m.Password
	}

	return entities.User{
		Id: m.Id,

		Name:  m.Name,
		Email: m.Email,

		Password: password,
	}
}
