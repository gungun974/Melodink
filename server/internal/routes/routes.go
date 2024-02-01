package routes

import (
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/improbable-eng/grpc-web/go/grpcweb"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"gungun974.com/melodink-server/internal"
	"gungun974.com/melodink-server/internal/logger"
)

func MainRouter(container internal.Container) http.Handler {
	router := chi.NewRouter()

	grpcServer := grpc.NewServer()

	wrappedGrpc := grpcweb.WrapServer(grpcServer)
	reflection.Register(grpcServer)

	router.Use(middleware.StripSlashes)
	router.Use(middleware.RequestID)
	router.Use(middleware.RealIP)
	router.Use(middleware.Logger)

	TrackGRPCRouter(container, grpcServer)
	router.Mount("/api/track", TrackHTTPRouter(container))

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")

		w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE")

		w.Header().Set("Access-Control-Allow-Headers", "Accept, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, X-User-Agent, X-Grpc-web")

		if r.Method == "OPTIONS" {
			return
		}

		if r.ProtoMajor == 2 && strings.Contains(r.Header.Get("Content-Type"), "application/grpc") {
			grpcServer.ServeHTTP(w, r)
			return
		}

		if wrappedGrpc.IsGrpcWebRequest(r) {
			logger.HTTPLogger.Info("GRPCWEB")
			wrappedGrpc.ServeHTTP(w, r)
			return
		}

		router.ServeHTTP(w, r)
	})
}
