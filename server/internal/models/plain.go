package models

import (
	"net/http"

	"github.com/gungun974/Melodink/server/internal/logger"
)

type PlainAPIResponse struct {
	Status int
	Text   string
}

func (r PlainAPIResponse) WriteResponse(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "text/plain")

	if r.Status > 0 {
		w.WriteHeader(r.Status)
	}

	_, err := w.Write([]byte(r.Text))
	if err != nil {
		logger.MainLogger.Errorf("Failed to write Plain API Response : %v", err)
	}
}
