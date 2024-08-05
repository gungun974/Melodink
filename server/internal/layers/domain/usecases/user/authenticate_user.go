package user_usecase

import (
	"context"
	"errors"
	"time"

	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"golang.org/x/crypto/bcrypt"
)

func CheckPasswordHash(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

func (u *UserUsecase) AuthenticateUser(
	ctx context.Context,
	email string,
	password string,
) (string, time.Time, error) {
	user, err := u.userRepository.GetUserWithPasswordByEmail(email)
	if err != nil {
		if errors.Is(err, repository.UserNotFoundError) {
			return "", time.Time{}, entities.NewUnauthorizedError()
		}

		logger.HTTPLogger.Errorf("Unknown error has occurred : %v", err)

		return "", time.Time{}, entities.NewUnauthorizedError()
	}

	if !CheckPasswordHash(password, user.Password) {
		return "", time.Time{}, entities.NewUnauthorizedError()
	}

	return generateAuthToken(*user)
}
