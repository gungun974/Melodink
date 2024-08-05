package user_usecase

import (
	"context"
	"errors"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
)

func (u *UserUsecase) GenerateUserAuthToken(
	ctx context.Context,
	userId int,
) (string, time.Time, error) {
	user, err := u.userRepository.GetUser(userId)
	if err != nil {
		if errors.Is(err, repository.UserNotFoundError) {
			return "", time.Time{}, entities.NewNotFoundError("User was not found")
		}

		return "", time.Time{}, entities.NewInternalError(err)
	}

	return generateAuthToken(*user)
}

func generateAuthToken(user entities.User) (string, time.Time, error) {
	refreshExpirationTime := time.Now().Add(31 * 24 * time.Hour)
	jwtExpirationTime := time.Now().Add(15 * time.Minute)

	claims := &entities.UserJWTClaims{
		UserId:            user.Id,
		RefreshExpireTime: refreshExpirationTime,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(jwtExpirationTime),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	tokenString, err := token.SignedString([]byte(os.Getenv("APP_JWT_KEY")))
	if err != nil {
		logger.HTTPLogger.Errorf("Unknown error has occurred : %v", err)

		return "", time.Time{}, entities.NewUnauthorizedError()
	}

	return tokenString, refreshExpirationTime, nil
}
