package entities

import (
	"errors"
	"fmt"
	"net/http"
	"runtime"
)

type AppError struct {
	Code    int
	Message string
	Caller  string
}

func (err *AppError) Error() string {
	return err.Message
}

func getCaller() string {
	pc, _, line, _ := runtime.Caller(2)
	details := runtime.FuncForPC(pc)

	return fmt.Sprintf("%s#%d", details.Name(), line)
}

type NotFoundError struct {
	AppError
}

func NewNotFoundError(msg string) error {
	return &NotFoundError{AppError{
		Code:    http.StatusNotFound,
		Message: msg,
		Caller:  getCaller(),
	}}
}

type ValidationError struct {
	AppError
}

func NewValidationError(msg string) error {
	return &ValidationError{AppError{
		Code:    http.StatusBadRequest,
		Message: msg,
		Caller:  getCaller(),
	}}
}

type UnauthorizedError struct {
	AppError
}

func NewUnauthorizedError() error {
	return &UnauthorizedError{AppError{
		Code:   http.StatusUnauthorized,
		Caller: getCaller(),
	}}
}

type InternalError struct {
	AppError
}

func NewInternalError(err error) error {
	return errors.Join(&InternalError{AppError{
		Code:    http.StatusInternalServerError,
		Message: err.Error(),
		Caller:  getCaller(),
	}}, err)
}

type GenericError struct {
	AppError
}

func NewGenericError(code int, msg string) error {
	return &GenericError{AppError{
		Code:    code,
		Message: msg,
		Caller:  getCaller(),
	}}
}
