package models

import (
	"bytes"
	"io"
	"net/http"

	"github.com/gungun974/Melodink/server/internal/logger"
)

type ImageAPIResponse struct {
	Status   int
	MIMEType string
	Data     bytes.Buffer
}

func (r ImageAPIResponse) WriteResponse(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", r.MIMEType)

	if r.Status > 0 {
		w.WriteHeader(r.Status)
	}

	_, err := io.Copy(w, &r.Data)
	if err != nil {
		logger.MainLogger.Errorf("Failed to write Image API Response : %v", err)
	}
}
