package models

import (
	"io"
	"net/http"

	"github.com/gungun974/Melodink/server/internal/logger"
)

type ReaderAPIResponse struct {
	Status   int
	MIMEType string
	Reader   io.ReadCloser
}

func (r ReaderAPIResponse) WriteResponse(w http.ResponseWriter, _ *http.Request) {
	defer r.Reader.Close()

	w.Header().Set("Content-Type", r.MIMEType)

	if r.Status > 0 {
		w.WriteHeader(r.Status)
	}

	_, err := io.Copy(w, r.Reader)
	if err != nil {
		logger.MainLogger.Errorf("Failed to write Reader API Response : %v", err)
	}
}
