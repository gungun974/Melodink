package internal

import (
	"github.com/jmoiron/sqlx"
	processor_impl "gungun974.com/melodink-server/internal/layers/data/processors"
	repository_impl "gungun974.com/melodink-server/internal/layers/data/repository"
	storage_impl "gungun974.com/melodink-server/internal/layers/data/storage"
	playlist_usecase "gungun974.com/melodink-server/internal/layers/domain/usecases/playlist"
	track_usecase "gungun974.com/melodink-server/internal/layers/domain/usecases/track"
	"gungun974.com/melodink-server/internal/layers/presentation/controllers"
	presenter_impl "gungun974.com/melodink-server/internal/layers/presentation/presenters"
)

type Container struct {
	TrackController    controllers.TrackController
	PlaylistController controllers.PlaylistController
}

func NewContainer(db *sqlx.DB) Container {
	container := Container{}

	//! Repository

	trackRepository := repository_impl.NewTrackRepository(db)
	playlistRepository := repository_impl.NewPlaylistRepository(db, trackRepository)

	//! Storage

	trackStorage := storage_impl.NewTrackStorage()

	//! Processor

	audioProcessor := processor_impl.NewAudioProcessor()

	//! Presenter

	trackPresenter := presenter_impl.NewTrackPresenterImpl()
	playlistPresenter := presenter_impl.NewPlaylistPresenterImpl()

	//! Usecase

	trackUsecase := track_usecase.NewTrackUsecase(
		trackRepository,
		trackStorage,
		audioProcessor,
		trackPresenter,
	)

	playlistUsecase := playlist_usecase.NewPlaylistUsecase(
		playlistRepository,
		playlistPresenter,
	)

	//! Controller

	container.TrackController = controllers.NewTrackController(trackUsecase)

	container.PlaylistController = controllers.NewPlaylistController(playlistUsecase)

	return container
}
