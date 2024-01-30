package main

import (
	"gungun974.com/melodink-server/internal"
	"gungun974.com/melodink-server/internal/database"
	"gungun974.com/melodink-server/internal/logger"
)

func main() {
	logger.MainLogger.Info("Melodink Server")

	db := database.Connect()

	container := internal.NewContainer(db)

	err := container.TrackUsecase.DiscoverNewTracks()
	if err != nil {
		logger.MainLogger.Fatal(err)
	}
}
