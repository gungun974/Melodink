package models

import (
	"encoding/json"
	"net/http"

	"gungun974.com/melodink-server/internal/logger"
)

type JsonAPIResponse struct {
	Status int
	Data   interface{} `json:"data,omitempty"`
}

func (r JsonAPIResponse) WriteResponse(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Status > 0 {
		w.WriteHeader(r.Status)
	}

	err := json.NewEncoder(w).Encode(r.Data)
	if err != nil {
		logger.MainLogger.Errorf("Failed to encode JSON API Response : %v", err)
	}
}
