package main

import (
	"net"
	"net/http"
	"os"

	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"
	"gungun974.com/melodink-server/internal"
	"gungun974.com/melodink-server/internal/database"
	"gungun974.com/melodink-server/internal/logger"
	"gungun974.com/melodink-server/internal/routes"
)

func main() {
	logger.MainLogger.Info("Melodink Server")

	db := database.Connect()

	container := internal.NewContainer(db)

	port := os.Getenv("PORT")

	if port == "" {
		port = "8000"
	}

	listener, err := net.Listen("tcp", "0.0.0.0:"+port)
	if err != nil {
		logger.MainLogger.Fatalf("Failed to create listener on port %s : %v", port, err)
	}

	router := routes.MainRouter(container)

	h2s := &http2.Server{}
	server := &http.Server{
		Addr:    "0.0.0.0:" + port,
		Handler: h2c.NewHandler(router, h2s),
	}

	logger.MainLogger.Infof("🦑 Melodink server is running at http://127.0.0.1:%s", port)

	if err := server.Serve(listener); err != nil {
		logger.MainLogger.Fatalf("Failed to serve : %v", err)
	}
}
