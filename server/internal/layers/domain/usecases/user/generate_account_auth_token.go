package user_usecase

import (
	"context"
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	config_key "github.com/gungun974/Melodink/server/internal/config"
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
)

func (u *UserUsecase) GenerateUserAuthToken(
	ctx context.Context,
	userId int,
) (string, time.Time, error) {
	jwtKey, err := u.configRepository.GetString(config_key.CONFIG_KEY_JWT)
	if err != nil {
		logger.MainLogger.Fatalf("Can't find config JWT key %v", err)
	}

	user, err := u.userRepository.GetUser(userId)
	if err != nil {
		if errors.Is(err, repositories.UserNotFoundError) {
			return "", time.Time{}, entities.NewNotFoundError("User was not found")
		}

		return "", time.Time{}, entities.NewInternalError(err)
	}

	return generateAuthToken(*user, jwtKey)
}

func generateAuthToken(user entities.User, key string) (string, time.Time, error) {
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

	tokenString, err := token.SignedString([]byte(key))
	if err != nil {
		logger.HTTPLogger.Errorf("Unknown error has occurred : %v", err)

		return "", time.Time{}, entities.NewUnauthorizedError()
	}

	return tokenString, refreshExpirationTime, nil
}
