package internal

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	user_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/user"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/controller"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenter"
	"github.com/jmoiron/sqlx"
)

type Container struct {
	UserController controller.UserController
}

func NewContainer(db *sqlx.DB) Container {
	container := Container{}

	//! Repository

	userRepository := repository.NewUserRepository(db)

	//! Presenter

	userPresenter := presenter.NewUserPresenter()

	//! Usecase

	userUsecase := user_usecase.NewUserUsecase(
		userRepository,
		userPresenter,
	)

	//! Controller

	container.UserController = controller.NewUserController(userUsecase)

	return container
}
