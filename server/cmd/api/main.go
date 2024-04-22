package main

import (
	"net/http"
	"os"

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

	router := routes.MainRouter(container)

	logger.MainLogger.Infof("🦑 Melodink server is running at http://127.0.0.1:%s", port)

	err := http.ListenAndServe(":"+port, router)
	if err != nil {
		logger.MainLogger.Fatalf("Failed to start HTTP server on port %s : %v", port, err)
	}
}
