package scheduler

import (
	"github.com/go-co-op/gocron/v2"
	"github.com/gungun974/Melodink/server/internal"
	"github.com/gungun974/Melodink/server/internal/logger"
)

func StartScheduler(c internal.Container) error {
	s, err := gocron.NewScheduler()
	if err != nil {
		return err
	}

	if err = startHlsScheduler(s, c); err != nil {
		return err
	}

	s.Start()
	logger.SchedulerLogger.Infoln("🕒 Start the scheduler")

	return nil
}
