package middlewares

import (
	"net/http"
	"regexp"

	"github.com/go-chi/chi/v5/middleware"
)

func AdvancedConditionalLogger(rawRegexes []string) func(next http.Handler) http.Handler {
	regexes := make([]*regexp.Regexp, len(rawRegexes))

	for i, regex := range rawRegexes {
		regexes[i] = regexp.MustCompile(regex)
	}

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			for _, regex := range regexes {
				if regex.MatchString(r.URL.Path) {
					next.ServeHTTP(w, r)
					return
				}
			}
			middleware.Logger(next).ServeHTTP(w, r)
		})
	}
}
