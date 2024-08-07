package routes

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/gungun974/Melodink/server/internal"
)

func TrackRouter(c internal.Container) http.Handler {
	router := chi.NewRouter()

	router.Post("/upload", func(w http.ResponseWriter, r *http.Request) {
		response, err := c.TrackController.UploadAudio(r.Context(), r)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/", func(w http.ResponseWriter, r *http.Request) {
		response, err := c.TrackController.ListUserTracks(r.Context())
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.TrackController.GetTrack(r.Context(), id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	return router
}
