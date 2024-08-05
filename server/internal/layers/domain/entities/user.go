package entities

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type User struct {
	Id int

	Name  string
	Email string

	Password string
}

type UserJWTClaims struct {
	UserId            int       `json:"user_id"`
	RefreshExpireTime time.Time `json:"refresh_expire_time"`
	jwt.RegisteredClaims
}
