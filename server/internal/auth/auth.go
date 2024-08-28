package auth

import (
	"context"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/gungun974/Melodink/server/internal"
	context_key "github.com/gungun974/Melodink/server/internal/context"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
)

func AuthMiddleware(c internal.Container) func(next http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if !isAuthProtectedRoute(r.URL.Path) {
				next.ServeHTTP(w, r)
				return
			}

			auth, err := r.Cookie("access_token")
			if err != nil {
				handleNotLogged(next, w, r)
				return
			}

			token, err := parseToken(auth.Value)
			if err != nil {
				handleNotLogged(next, w, r)
				return
			}

			if isRefreshExpired(*token) {
				RemoveAuthCookie(w)

				handleNotLogged(next, w, r)
				return
			}

			ctx := r.Context()

			user, err := c.UserController.GetRawEntity(ctx, token.UserId)
			if err != nil {
				handleNotLogged(next, w, r)
				return
			}

			if isExpired(*token) {
				key, exp, err := c.UserController.GenerateAuthToken(r.Context(), user.Id)
				if err != nil {
					RemoveAuthCookie(w)

					logger.MainLogger.Warnf(
						"Failed to refresh authToken for user \"%s\"", user.Name,
					)

					handleNotLogged(next, w, r)
					return
				}

				SetAuthCookie(w, key, exp)
			}

			ctx = context.WithValue(ctx, context_key.LOGGED_USER_INFO_KEY, user)

			if r.URL.Path == "/login" {
				http.Redirect(w, r.WithContext(ctx), "/", http.StatusSeeOther)
				return
			}

			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func RemoveAuthCookie(w http.ResponseWriter) {
	authCookie := http.Cookie{
		Name:     "access_token",
		Path:     "/",
		HttpOnly: true,
		SameSite: http.SameSiteLaxMode,
		Expires:  time.Unix(0, 0),
		MaxAge:   -1,
	}

	http.SetCookie(w, &authCookie)
}

func SetAuthCookie(w http.ResponseWriter, key string, exp time.Time) {
	authCookie := http.Cookie{
		Name:     "access_token",
		Path:     "/",
		HttpOnly: true,
		SameSite: http.SameSiteLaxMode,
		Expires:  exp,
		Value:    key,
	}

	http.SetCookie(w, &authCookie)
}

func parseToken(tokenString string) (claims *entities.UserJWTClaims, err error) {
	parser := jwt.NewParser(jwt.WithoutClaimsValidation())

	token, err := parser.ParseWithClaims(
		tokenString,
		&entities.UserJWTClaims{},
		func(token *jwt.Token) (interface{}, error) {
			return []byte(os.Getenv("APP_JWT_KEY")), nil
		},
	)
	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*entities.UserJWTClaims)

	if !ok {
		return nil, err
	}

	return claims, nil
}

func isExpired(claims entities.UserJWTClaims) bool {
	if claims.ExpiresAt == nil {
		return true
	}
	return !claims.ExpiresAt.After(time.Now())
}

func isRefreshExpired(claims entities.UserJWTClaims) bool {
	return !claims.RefreshExpireTime.After(time.Now())
}

func handleNotLogged(
	next http.Handler,
	w http.ResponseWriter,
	r *http.Request,
) {
	if r.URL.Path == "/login" {
		next.ServeHTTP(w, r)
		return
	}

	http.Error(w, http.StatusText(http.StatusUnauthorized), http.StatusUnauthorized)
}

func isAuthProtectedRoute(path string) bool {
	return !strings.HasPrefix(path, "/login") && !strings.HasPrefix(path, "/register") &&
		!strings.HasPrefix(path, "/check")
}
