package scheduler

import (
	"time"

	"github.com/go-co-op/gocron/v2"
	"github.com/gungun974/Melodink/server/internal"
	"github.com/gungun974/Melodink/server/internal/logger"
)

func startHlsScheduler(s gocron.Scheduler, c internal.Container) error {
	_, err := s.NewJob(gocron.DurationJob(30*time.Minute), gocron.NewTask(func() {
		logger.SchedulerLogger.Infoln("Start cleaning old HLS streams")

		start := time.Now()

		err := c.HlsController.CleanOldStreams()
		if err != nil {
			logger.SchedulerLogger.Errorf("Failed to clean old HLS streams : %v", err)
		}

		duration := time.Since(start)

		logger.SchedulerLogger.Infof("Finish cleaning old HLS streams in %s", duration)
	}), gocron.WithStartAt(gocron.WithStartImmediately()), gocron.WithSingletonMode(gocron.LimitModeReschedule))
	if err != nil {
		return err
	}

	return nil
}
