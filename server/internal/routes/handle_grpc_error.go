package routes

import (
	"errors"
	"net/http"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"gungun974.com/melodink-server/internal/layers/domain/entities"
	"gungun974.com/melodink-server/internal/logger"
)

func handleGRPCError(err error) error {
	var errNotFound *entities.NotFoundError
	var errValidation *entities.ValidationError
	var errUnauthorized *entities.UnauthorizedError
	var errInternal *entities.InternalError
	var errGeneric *entities.GenericError

	switch {
	case errors.As(err, &errNotFound):
		return status.Error(codes.NotFound, errNotFound.Message)
	case errors.As(err, &errValidation):
		return status.Error(codes.InvalidArgument, errValidation.Message)
	case errors.As(err, &errUnauthorized):
		return status.Error(codes.Unauthenticated, http.StatusText(errUnauthorized.Code))
	case errors.As(err, &errInternal):
		logger.HTTPLogger.Errorf("Internal Server Error have ocurred : %v", err)
		return status.Error(codes.Internal, http.StatusText(errInternal.Code))
	case errors.As(err, &errGeneric):
		return status.Error(codes.Unknown, http.StatusText(errInternal.Code))
	default:
		logger.HTTPLogger.Errorf("Unknown error have ocurred : %v", err)
		return status.Error(codes.Unknown, http.StatusText(errInternal.Code))
	}
}
