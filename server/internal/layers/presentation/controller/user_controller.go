package controller

import (
	"context"
	"time"

	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	user_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/user"
	"github.com/gungun974/validator"
)

type UserController struct {
	userUsecase user_usecase.UserUsecase
}

func NewUserController(
	userUsecase user_usecase.UserUsecase,
) UserController {
	return UserController{
		userUsecase,
	}
}

func (c *UserController) Authenticate(
	ctx context.Context,
	bodyData map[string]any,
) (string, time.Time, error) {
	email, err := validator.ValidateMapString(
		"email",
		bodyData,
		validator.StringValidators{
			validator.StringMaxValidator{Max: 128},
			validator.StringMinValidator{Min: 1},
			validator.StringEmailValidator{},
		},
	)
	if err != nil {
		return "", time.Time{}, entities.NewValidationError(err.Error())
	}

	password, err := validator.ValidateMapString(
		"password",
		bodyData,
		validator.StringValidators{
			validator.StringMinValidator{Min: 1},
			validator.StringMaxValidator{Max: 128},
		},
	)
	if err != nil {
		return "", time.Time{}, entities.NewValidationError(err.Error())
	}

	return c.userUsecase.AuthenticateUser(ctx, email, password)
}

func (c *UserController) GetRawEntity(
	ctx context.Context,
	userId int,
) (entities.User, error) {
	return c.userUsecase.GetRawUserEntity(ctx, userId)
}

func (c *UserController) GenerateAuthToken(
	ctx context.Context,
	userId int,
) (string, time.Time, error) {
	return c.userUsecase.GenerateUserAuthToken(ctx, userId)
}
