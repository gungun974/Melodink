package routes

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/gungun974/Melodink/server/internal"
)

func AlbumRouter(c internal.Container) http.Handler {
	router := chi.NewRouter()

	router.Get("/", func(w http.ResponseWriter, r *http.Request) {
		response, err := c.AlbumController.ListUserAlbums(r.Context())
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/full", func(w http.ResponseWriter, r *http.Request) {
		response, err := c.AlbumController.ListUserAlbumsWithTracks(r.Context())
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.AlbumController.GetUserAlbum(r.Context(), id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/cover", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.AlbumController.GetUserAlbumCover(r.Context(), id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/cover/small", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.AlbumController.GetCompressedUserAlbumCover(r.Context(), id, "small")
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/cover/medium", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.AlbumController.GetCompressedUserAlbumCover(r.Context(), id, "medium")
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/cover/high", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.AlbumController.GetCompressedUserAlbumCover(r.Context(), id, "high")
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Put("/{id}/cover", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.AlbumController.ChangeAlbumCover(r.Context(), r, id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/cover/signature", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.AlbumController.GetAlbumCoverSignature(r.Context(), id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/cover/custom/signature", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.AlbumController.GetAlbumCustomCoverSignature(r.Context(), id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/covers/signatures", func(w http.ResponseWriter, r *http.Request) {
		response, err := c.AlbumController.GetAllAlbumsCoverSignatures(r.Context())
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Delete("/{id}/cover", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.AlbumController.DeleteAlbumCover(r.Context(), id)
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

		response, err := c.AlbumController.CreateAlbum(r.Context(), bodyData)
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

		response, err := c.AlbumController.EditAlbum(r.Context(), id, bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Post("/{id}/tracks", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		var bodyData map[string]any

		err := json.NewDecoder(r.Body).Decode(&bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response, err := c.AlbumController.AddAlbumTracks(r.Context(), id, bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Delete("/{id}/tracks", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		var bodyData map[string]any

		err := json.NewDecoder(r.Body).Decode(&bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response, err := c.AlbumController.RemoveAlbumTracks(r.Context(), id, bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Put("/{id}/artists", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		var bodyData map[string]any

		err := json.NewDecoder(r.Body).Decode(&bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response, err := c.AlbumController.SetAlbumArtists(r.Context(), id, bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Delete("/{id}", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.AlbumController.DeleteAlbum(r.Context(), id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	return router
}
