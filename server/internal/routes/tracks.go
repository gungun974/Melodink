package routes

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/gungun974/Melodink/server/internal"
)

func TrackRouter(c internal.Container) http.Handler {
	router := chi.NewRouter()

	router.Post("/upload", func(w http.ResponseWriter, r *http.Request) {
		queryParams := r.URL.Query()

		performAdvancedScan := strings.TrimSpace(queryParams.Get("advanced_scan")) == "true"
		advancedScanOnlyReplaceEmptyFields := !(strings.TrimSpace(
			queryParams.Get("advanced_scan_only_replace_empty_fields"),
		) == "false")

		response, err := c.TrackController.UploadAudio(
			r.Context(),
			r,
			performAdvancedScan,
			advancedScanOnlyReplaceEmptyFields,
		)
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

	router.Get("/import", func(w http.ResponseWriter, r *http.Request) {
		response, err := c.TrackController.ListPendingImportTracks(r.Context())
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

	router.Get("/{id}/cover", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.TrackController.GetCover(r.Context(), id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/cover/small", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.TrackController.GetCompressedCover(r.Context(), id, "small")
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/cover/medium", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.TrackController.GetCompressedCover(r.Context(), id, "medium")
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/cover/high", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.TrackController.GetCompressedCover(r.Context(), id, "high")
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/audio", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.TrackController.GetTrackAudio(r.Context(), id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	for _, quality := range []string{"low", "medium", "high", "max"} {
		router.Get(
			"/{id}/audio/"+quality+"/transcode",
			func(w http.ResponseWriter, r *http.Request) {
				id := chi.URLParam(r, "id")

				err := c.TrackController.GetTrackAudioWithTranscode(r.Context(), id, quality, w, r)
				if err != nil {
					handleHTTPError(err, w)
					return
				}
			},
		)
	}

	router.Get("/{id}/signature", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.TrackController.GetTrackFileSignature(r.Context(), id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/cover/signature", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.TrackController.GetTrackCoverSignature(r.Context(), id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/extension", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.TrackController.GetTrackFileExtension(r.Context(), id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/lyrics", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.TrackController.GetTrackLyrics(r.Context(), id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/scan", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		queryParams := r.URL.Query()

		performAdvancedScan := strings.TrimSpace(queryParams.Get("advanced_scan")) == "true"
		advancedScanOnlyReplaceEmptyFields := !(strings.TrimSpace(
			queryParams.Get("advanced_scan_only_replace_empty_fields"),
		) == "false")

		response, err := c.TrackController.ScanTrack(
			r.Context(),
			id,
			performAdvancedScan,
			advancedScanOnlyReplaceEmptyFields,
		)
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

		response, err := c.TrackController.EditTrack(r.Context(), id, bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Put("/{id}/score", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		var bodyData map[string]any

		err := json.NewDecoder(r.Body).Decode(&bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response, err := c.TrackController.SetTrackScore(r.Context(), id, bodyData)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Put("/{id}/audio", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.TrackController.ChangeTrackAudio(r.Context(), r, id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Put("/{id}/cover", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.TrackController.ChangeTrackCover(r.Context(), r, id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Post("/import", func(w http.ResponseWriter, r *http.Request) {
		response, err := c.TrackController.ImportPendingTracks(r.Context())
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Delete("/{id}", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.TrackController.DeleteTrack(r.Context(), id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	return router
}
