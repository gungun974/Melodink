package helpers

import (
	"context"

	context_key "github.com/gungun974/Melodink/server/internal/context"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

func ExtractCurrentLoggedUser(ctx context.Context) (entities.User, error) {
	user, ok := ctx.Value(context_key.LOGGED_USER_INFO_KEY).(entities.User)

	if !ok {
		return entities.User{}, entities.NewUnauthorizedError()
	}

	return user, nil
}
