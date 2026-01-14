package user_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

func (u *UserUsecase) GetRawUserEntity(
	ctx context.Context,
	userId int,
) (entities.User, error) {
	user, err := u.userRepository.GetUser(userId)
	if err != nil {
		if errors.Is(err, repositories.UserNotFoundError) {
			return entities.User{}, entities.NewNotFoundError("User was not found")
		}

		return entities.User{}, entities.NewInternalError(err)
	}

	return *user, nil
}
