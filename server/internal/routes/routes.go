package routes

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/gungun974/Melodink/server/internal"
	"github.com/gungun974/Melodink/server/internal/auth"
	"github.com/gungun974/Melodink/server/internal/middlewares"
)

func MainRouter(container internal.Container) http.Handler {
	router := chi.NewRouter()

	router.Use(cors.Handler(cors.Options{
		AllowedOrigins: []string{"https://*", "http://*"},
		AllowedMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
	}))

	router.Use(middleware.StripSlashes)
	router.Use(middleware.RequestID)
	router.Use(middleware.RealIP)
	router.Use(middlewares.AdvancedConditionalLogger([]string{
		"/health",
	}))

	router.Use(middleware.Recoverer)

	router.Use(middleware.Compress(5))

	router.Use(auth.AuthMiddleware(container))

	UserRouter(container, router)

	router.Mount("/track", TrackRouter(container))
	router.Mount("/playlist", PlaylistRouter(container))
	router.Mount("/album", AlbumRouter(container))
	router.Mount("/artist", ArtistRouter(container))

	router.Get("/check", func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte("IamAMelodinkCompatibleServer"))
	})

	router.Get("/uuid", func(w http.ResponseWriter, r *http.Request) {
		response := container.ConfigController.GetServerUUID(r.Context())

		response.WriteResponse(w, r)
	})

	router.Get("/health", func(w http.ResponseWriter, r *http.Request) {})

	router.Get("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("Hoi"))
	})

	FileRouter(router)

	return router
}
