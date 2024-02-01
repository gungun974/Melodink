package routes

import (
	"errors"
	"net/http"

	"gungun974.com/melodink-server/internal/layers/domain/entities"
	"gungun974.com/melodink-server/internal/logger"
)

func handleHTTPError(err error, w http.ResponseWriter) {
	var errNotFound *entities.NotFoundError
	var errValidation *entities.ValidationError
	var errUnauthorized *entities.UnauthorizedError
	var errInternal *entities.InternalError
	var errGeneric *entities.GenericError

	switch {
	case errors.As(err, &errNotFound):
		http.Error(w, errNotFound.Message, errNotFound.Code)
		return
	case errors.As(err, &errValidation):
		http.Error(w, http.StatusText(errValidation.Code), errValidation.Code)
		return
	case errors.As(err, &errUnauthorized):
		http.Error(w, http.StatusText(errUnauthorized.Code), errUnauthorized.Code)
		return
	case errors.As(err, &errInternal):
		logger.HTTPLogger.Errorf("Internal Server Error have ocurred : %v", err)
		http.Error(w, http.StatusText(errInternal.Code), errInternal.Code)
		return
	case errors.As(err, &errGeneric):
		http.Error(w, http.StatusText(errGeneric.Code), errGeneric.Code)
		return
	default:
		logger.HTTPLogger.Errorf("Unknown error have ocurred : %v", err)
		http.Error(w, http.StatusText(
			http.StatusInternalServerError,
		), http.StatusInternalServerError)
		return
	}
}

func HandleNotFoundPage(w http.ResponseWriter, r *http.Request) {
	http.NotFound(w, r)
}
