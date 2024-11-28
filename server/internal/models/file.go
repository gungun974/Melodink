package models

import (
	"net/http"
)

type FileAPIResponse struct {
	Status   int
	MIMEType string
	Path     string
}

func (ar FileAPIResponse) WriteResponse(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", ar.MIMEType)

	if ar.Status > 0 {
		w.WriteHeader(ar.Status)
	}

	http.ServeFile(w, r, ar.Path)
}
