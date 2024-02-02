package models

import (
	"net/http"
)

type RedirectAPIResponse struct {
	Status int
	Url    string
}

func (p RedirectAPIResponse) WriteResponse(w http.ResponseWriter, r *http.Request) {
	http.Redirect(w, r, p.Url, p.Status)
}
