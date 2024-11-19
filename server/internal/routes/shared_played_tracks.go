package routes

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/gungun974/Melodink/server/internal"
)

func SharedPlayedTrackRouter(c internal.Container) http.Handler {
	router := chi.NewRouter()

	router.Post("/upload", func(w http.ResponseWriter, r *http.Request) {
		var bodyData map[string]any

		err := json.NewDecoder(r.Body).Decode(&bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response, err := c.SharedPlayedTrackController.UploadPlayedTrack(
			r.Context(),
			bodyData,
		)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/from/{id}", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.SharedPlayedTrackController.GetFromIdToLast(r.Context(), id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	return router
}
