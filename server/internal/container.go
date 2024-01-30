package internal

import (
	"github.com/jmoiron/sqlx"
	repository_impl "gungun974.com/melodink-server/internal/layers/data/repository"
	storage_impl "gungun974.com/melodink-server/internal/layers/data/storage"
	track_usecase "gungun974.com/melodink-server/internal/layers/domain/usecases/track"
)

type Container struct {
	TrackUsecase track_usecase.TrackUsecase
}

func NewContainer(db *sqlx.DB) Container {
	container := Container{}

	//! Repository

	trackRepository := repository_impl.NewTrackRepository(db)

	//! Storage

	trackStorage := storage_impl.NewTrackStorage()

	//! Usecase

	container.TrackUsecase = track_usecase.NewTrackUsecase(
		trackRepository,
		trackStorage,
	)

	return container
}
