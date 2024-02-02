package internal

import (
	"github.com/jmoiron/sqlx"
	processor_impl "gungun974.com/melodink-server/internal/layers/data/processors"
	repository_impl "gungun974.com/melodink-server/internal/layers/data/repository"
	storage_impl "gungun974.com/melodink-server/internal/layers/data/storage"
	track_usecase "gungun974.com/melodink-server/internal/layers/domain/usecases/track"
	"gungun974.com/melodink-server/internal/layers/presentation/controllers"
	presenter_impl "gungun974.com/melodink-server/internal/layers/presentation/presenters"
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

	//! Processor

	audioProcessor := processor_impl.NewAudioProcessor()

	//! Presenter

	trackPresenter := presenter_impl.NewTrackPresenterImpl()

	//! Usecase

	trackUsecase := track_usecase.NewTrackUsecase(
		trackRepository,
		trackStorage,
		audioProcessor,
		trackPresenter,
	)

	//! Controller

	container.TrackController = controllers.NewTrackController(trackUsecase)

	return container
}
