package presenter

import (
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	view_models "github.com/gungun974/Melodink/server/internal/layers/presentation/models"
	"github.com/gungun974/Melodink/server/internal/models"
)

func NewUserPresenter() UserPresenter {
	return UserPresenter{}
}

type UserPresenter struct{}

func (p *UserPresenter) ShowUsers(
	users []entities.User,
) models.APIResponse {
	usersViewModels := make([]view_models.UserViewModel, len(users))

	for i, user := range users {
		usersViewModels[i] = view_models.ConvertToUserViewModel(user)
	}

	return models.JsonAPIResponse{
		Data: usersViewModels,
	}
}

func (p *UserPresenter) ShowUser(
	user entities.User,
) models.APIResponse {
	return models.JsonAPIResponse{
		Data: view_models.ConvertToUserViewModel(user),
	}
}
