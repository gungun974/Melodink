package user_usecase

import (
	"context"
	"errors"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/models"
	"golang.org/x/crypto/bcrypt"
)

func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	return string(bytes), err
}

func (u *UserUsecase) RegisterUser(
	ctx context.Context,
	name string,
	email string,
	password string,
) (models.APIResponse, error) {
	hash, err := HashPassword(password)
	if err != nil {
		return nil, entities.NewInternalError(err)
	}

	newUser, err := u.userRepository.CreateUser(name, email, hash)
	if err != nil {
		logger.MainLogger.Error("Couldn't create user", err)
		return nil, entities.NewInternalError(errors.New("Failed to create user"))
	}

	return u.userPresenter.ShowUser(*newUser), nil
}
