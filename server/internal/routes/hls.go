package routes

import (
	"bufio"
	"context"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/gungun974/Melodink/server/internal"
)

func HlsRouter(c internal.Container) http.Handler {
	router := chi.NewRouter()

	router.Get("/{id}/*", func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 60*time.Second)
		defer cancel()

		id := chi.URLParam(r, "id")
		filePath := chi.URLParam(r, "*")

		waitAndServe(ctx, c, id, "./data/hls/"+id+"/"+filePath, w, r)

		_ = c.HlsController.MarkStreamUse(id)
	})

	return router
}

func waitAndServe(
	ctx context.Context,
	c internal.Container,
	trackId string,
	path string,
	w http.ResponseWriter,
	r *http.Request,
) {
	if _, err := os.Stat(path); err == nil {
		if c.HlsController.CheckStreamSectionReady(trackId, filepath.Base(path)) &&
			isPlaylistReady(path) {
			http.ServeFile(w, r, path)
			return
		}
	}

	ticker := time.NewTicker(50 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		// case <-ctx.Done():
		// 	http.Error(w, "Timeout waiting for file", http.StatusGatewayTimeout)
		// 	return

		case <-ticker.C:
			if _, err := os.Stat(path); err == nil {
				if c.HlsController.CheckStreamSectionReady(trackId, filepath.Base(path)) &&
					isPlaylistReady(path) {
					http.ServeFile(w, r, path)
					return
				}
			}
		}
	}
}

func isPlaylistReady(path string) bool {
	if filepath.Ext(path) != ".m3u8" {
		return true
	}

	if filepath.Base(path) == "master.m3u8" {
		return true
	}

	file, err := os.Open(path)
	if err != nil {
		return true
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "#EXT-X-ENDLIST") {
			return true
		}
	}

	return false
}
