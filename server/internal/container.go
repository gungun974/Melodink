package internal

import (
	"github.com/jmoiron/sqlx"
)

type Container struct{}

func NewContainer(db *sqlx.DB) Container {
	container := Container{}

	return container
}
