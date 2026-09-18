package view_models

import "github.com/gungun974/Melodink/server/internal/layers/domain/entities"

type UserViewModel struct {
	Id int `json:"id"`

	Name  string `json:"name"`
	Email string `json:"email"`
}

func ConvertToUserViewModel(
	user entities.User,
) UserViewModel {
	return UserViewModel{
		Id:   user.Id,
		Name: user.Name,

		Email: user.Email,
	}
}

type LoginViewModel struct {
	User UserViewModel `json:"user"`

	AccessToken string `json:"access_token"`
}
