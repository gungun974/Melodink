package user_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenter"
)

type UserUsecase struct {
	userRepository repository.UserRepository
	userPresenter  presenter.UserPresenter
}

func NewUserUsecase(
	userRepository repository.UserRepository,
	userPresenter presenter.UserPresenter,
) UserUsecase {
	return UserUsecase{
		userRepository,
		userPresenter,
	}
}
