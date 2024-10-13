package user_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenter"
)

type UserUsecase struct {
	userRepository   repository.UserRepository
	configRepository repository.ConfigRepository
	userPresenter    presenter.UserPresenter
}

func NewUserUsecase(
	userRepository repository.UserRepository,
	configRepository repository.ConfigRepository,
	userPresenter presenter.UserPresenter,
) UserUsecase {
	return UserUsecase{
		userRepository,
		configRepository,
		userPresenter,
	}
}
