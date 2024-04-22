package routes

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"gungun974.com/melodink-server/internal"
	"gungun974.com/melodink-server/internal/middlewares"
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
		"/api/track/[0-9]+/image",
	}))

	router.Use(middleware.Compress(5))

	router.Mount("/api/track", TrackRouter(container))

	router.Mount("/api/playlist", PlaylistRouter(container))

	FileRouter(router)

	return router
}
