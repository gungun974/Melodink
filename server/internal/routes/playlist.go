package routes

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"gungun974.com/melodink-server/internal"
)

func PlaylistRouter(c internal.Container) http.Handler {
	router := chi.NewRouter()

	router.Get("/album", func(w http.ResponseWriter, r *http.Request) {
		response, err := c.PlaylistController.ListAllAlbums()
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/album/{id}", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.PlaylistController.GetAlbum(id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	return router
}
