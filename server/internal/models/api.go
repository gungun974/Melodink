package models

import "net/http"

type APIResponse interface {
	WriteResponse(w http.ResponseWriter, r *http.Request)
}
