package models

import (
	"io"
	"net/http"
	"strconv"

	"github.com/gungun974/Melodink/server/internal/logger"
)

type ReaderAPIResponse struct {
	Status   int
	MIMEType string
	Reader   io.ReadCloser
	Size     int64
}

func (r ReaderAPIResponse) WriteResponse(w http.ResponseWriter, _ *http.Request) {
	defer r.Reader.Close()

	w.Header().Set("Content-Type", r.MIMEType)

	if r.Status > 0 {
		w.WriteHeader(r.Status)
	}

	if r.Size > 0 {
		fileSize := strconv.FormatInt(r.Size, 10)
		w.Header().Set("Content-Length", fileSize)
	}

	_, err := io.Copy(w, r.Reader)
	if err != nil {
		logger.MainLogger.Errorf("Failed to write Reader API Response : %v", err)
	}
}
