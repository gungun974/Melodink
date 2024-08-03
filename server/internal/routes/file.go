package routes

import (
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/go-chi/chi/v5"
)

func FileRouter(router chi.Router) {
	executablePath, _ := os.Executable()

	workDir := filepath.Dir(executablePath)
	filesDir := http.Dir(filepath.Join(workDir, "public"))
	FileServer(router, "/", filesDir)
}

// FileServer conveniently sets up a http.FileServer handler to serve
// static files from a http.FileSystem.
func FileServer(r chi.Router, path string, root http.FileSystem) {
	if strings.ContainsAny(path, "{}*") {
		panic("FileServer does not permit any URL parameters.")
	}

	if path != "/" && path[len(path)-1] != '/' {
		r.Get(path, http.RedirectHandler(path+"/", 301).ServeHTTP)
		path += "/"
	}
	path += "*"

	r.Get(path, func(w http.ResponseWriter, r *http.Request) {
		context := chi.RouteContext(r.Context())
		pathPrefix := strings.TrimSuffix(context.RoutePattern(), "/*")
		fs := http.StripPrefix(pathPrefix, http.FileServer(root))

		f, err := root.Open(r.URL.Path)
		if err != nil {
			HandleNotFoundPage(w, r)
			return
		}
		defer f.Close()

		info, err := f.Stat()
		if err != nil {
			HandleNotFoundPage(w, r)
			return
		}

		if info.IsDir() {
			HandleNotFoundPage(w, r)
			return
		}

		fs.ServeHTTP(w, r)
	})
}
