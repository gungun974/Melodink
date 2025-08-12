package routes

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/gungun974/Melodink/server/internal"
)

func SyncRouter(c internal.Container) http.Handler {
	router := chi.NewRouter()

	router.Get("/", func(w http.ResponseWriter, r *http.Request) {
		response, err := c.SyncController.FetchFullSyncData(r.Context())
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{since}", func(w http.ResponseWriter, r *http.Request) {
		since := chi.URLParam(r, "since")

		response, err := c.SyncController.FetchPartialSyncData(r.Context(), since)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	return router
}
