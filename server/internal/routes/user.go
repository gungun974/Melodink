package routes

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/gungun974/Melodink/server/internal"
	"github.com/gungun974/Melodink/server/internal/auth"
)

func UserRouter(c internal.Container, router *chi.Mux) {
	router.Post("/login", func(w http.ResponseWriter, r *http.Request) {
		var bodyData map[string]any

		err := json.NewDecoder(r.Body).Decode(&bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		key, exp, err := c.UserController.Authenticate(r.Context(), bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		auth.SetAuthCookie(w, key, exp)

		_, _ = w.Write([]byte("ok"))
	})

	router.Get("/me", func(w http.ResponseWriter, r *http.Request) {
		response, err := c.UserController.GetCurrentLogged(r.Context())
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Post("/logout", func(w http.ResponseWriter, r *http.Request) {
		auth.RemoveAuthCookie(w)

		_, _ = w.Write([]byte("ok"))
	})

	router.Post("/register", func(w http.ResponseWriter, r *http.Request) {
		var bodyData map[string]any

		err := json.NewDecoder(r.Body).Decode(&bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response, err := c.UserController.Register(r.Context(), bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})
}
