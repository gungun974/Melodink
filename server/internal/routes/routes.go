package routes

import (
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"gungun974.com/melodink-server/internal"
)

func MainRouter(container internal.Container) http.Handler {
	router := chi.NewRouter()

	grpcServer := grpc.NewServer()
	reflection.Register(grpcServer)

	router.Use(middleware.StripSlashes)
	router.Use(middleware.RequestID)
	router.Use(middleware.RealIP)
	router.Use(middleware.Logger)

	TrackRouter(container, grpcServer)

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.ProtoMajor == 2 && strings.Contains(r.Header.Get("Content-Type"), "application/grpc") {
			grpcServer.ServeHTTP(w, r)
			return
		}

		router.ServeHTTP(w, r)
	})
}
