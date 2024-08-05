package internal

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/data/storage"
	track_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/track"
	user_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/user"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/controller"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenter"
	"github.com/jmoiron/sqlx"
)

type Container struct {
	UserController  controller.UserController
	TrackController controller.TrackController
}

func NewContainer(db *sqlx.DB) Container {
	container := Container{}

	//! Repository

	userRepository := repository.NewUserRepository(db)
	trackRepository := repository.NewTrackRepository(db)

	//! Storage

	trackStorage := storage.NewTrackStorage()

	//! Presenter

	userPresenter := presenter.NewUserPresenter()
	trackPresenter := presenter.NewTrackPresenter()

	//! Usecase

	userUsecase := user_usecase.NewUserUsecase(
		userRepository,
		userPresenter,
	)

	trackUsecase := track_usecase.NewTrackUsecase(
		trackRepository,
		trackStorage,
		trackPresenter,
	)

	//! Controller

	container.UserController = controller.NewUserController(userUsecase)
	container.TrackController = controller.NewTrackController(trackUsecase)

	return container
}
