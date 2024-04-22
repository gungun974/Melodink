package routes

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"gungun974.com/melodink-server/internal"
)

func TrackRouter(c internal.Container) http.Handler {
	router := chi.NewRouter()

	router.Get("/", func(w http.ResponseWriter, r *http.Request) {
		response, err := c.TrackController.GetAll()
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Post("/scan", func(w http.ResponseWriter, r *http.Request) {
		err := c.TrackController.DiscoverNewTracks()
		if err != nil {
			handleHTTPError(err, w)
			return
		}
	})

	router.Get("/{id}/image", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.TrackController.GetCover(id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/audio/{format}/{quality}/*", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")
		format := chi.URLParam(r, "format")
		quality := chi.URLParam(r, "quality")

		response, err := c.TrackController.FetchAudioStream(id, format, quality)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	return router
}
