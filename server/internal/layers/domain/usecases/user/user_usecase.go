package user_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenters"
)

type UserUsecase struct {
	userRepository   repositories.UserRepository
	configRepository repositories.ConfigRepository
	userPresenter    presenters.UserPresenter
}

func NewUserUsecase(
	userRepository repositories.UserRepository,
	configRepository repositories.ConfigRepository,
	userPresenter presenters.UserPresenter,
) UserUsecase {
	return UserUsecase{
		userRepository,
		configRepository,
		userPresenter,
	}
}
