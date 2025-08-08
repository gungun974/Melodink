package routes

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/gungun974/Melodink/server/internal"
)

func ArtistRouter(c internal.Container) http.Handler {
	router := chi.NewRouter()

	router.Get("/", func(w http.ResponseWriter, r *http.Request) {
		response, err := c.ArtistController.ListUserArtists(r.Context())
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.ArtistController.GetUserArtistAlbums(r.Context(), id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/tracks", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.ArtistController.GetUserArtistTracks(r.Context(), id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/cover", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.ArtistController.GetUserArtistCover(r.Context(), id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/cover/small", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.ArtistController.GetCompressedUserArtistCover(r.Context(), id, "small")
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/cover/medium", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.ArtistController.GetCompressedUserArtistCover(r.Context(), id, "medium")
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/cover/high", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.ArtistController.GetCompressedUserArtistCover(r.Context(), id, "high")
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Post("/", func(w http.ResponseWriter, r *http.Request) {
		var bodyData map[string]any

		err := json.NewDecoder(r.Body).Decode(&bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response, err := c.ArtistController.CreateArtist(r.Context(), bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Put("/{id}", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		var bodyData map[string]any

		err := json.NewDecoder(r.Body).Decode(&bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response, err := c.ArtistController.EditArtist(r.Context(), id, bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Delete("/{id}", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.ArtistController.DeleteArtist(r.Context(), id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	return router
}
