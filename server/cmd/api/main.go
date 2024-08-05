package main

import (
	"net/http"
	"os"

	"github.com/gungun974/Melodink/server/internal"
	"github.com/gungun974/Melodink/server/internal/database"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/gungun974/Melodink/server/internal/routes"
	"github.com/joho/godotenv"
)

func main() {
	err := godotenv.Load()

	if err == nil {
		logger.MainLogger.Info("Loading .env file")
	}

	if os.Getenv("APP_JWT_KEY") == "" {
		logger.DatabaseLogger.Fatalln("APP_JWT_KEY is not set")
	}

	logger.MainLogger.Info("Melodink Server")

	db := database.Connect()

	container := internal.NewContainer(db)

	port := os.Getenv("PORT")

	if port == "" {
		port = "8000"
	}

	router := routes.MainRouter(container)

	logger.MainLogger.Infof("🦑 Melodink server is running at http://127.0.0.1:%s", port)

	err = http.ListenAndServe(":"+port, router)
	if err != nil {
		logger.MainLogger.Fatalf("Failed to start HTTP server on port %s : %v", port, err)
	}
}
