package internal

import (
	"github.com/jmoiron/sqlx"
	repository_impl "gungun974.com/melodink-server/internal/layers/data/repository"
	storage_impl "gungun974.com/melodink-server/internal/layers/data/storage"
	track_usecase "gungun974.com/melodink-server/internal/layers/domain/usecases/track"
	"gungun974.com/melodink-server/internal/layers/presentation/controllers"
)

type Container struct {
	TrackController controllers.TrackController
}

func NewContainer(db *sqlx.DB) Container {
	container := Container{}

	//! Repository

	trackRepository := repository_impl.NewTrackRepository(db)

	//! Storage

	trackStorage := storage_impl.NewTrackStorage()

	//! Usecase

	trackUsecase := track_usecase.NewTrackUsecase(
		trackRepository,
		trackStorage,
	)

	//! Controller

	container.TrackController = controllers.NewTrackController(trackUsecase)

	return container
}
