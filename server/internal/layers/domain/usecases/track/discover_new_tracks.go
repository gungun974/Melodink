package track_usecase

import (
	"errors"
	"os"
	"sync"

	"gungun974.com/melodink-server/internal/layers/domain/entities"
	"gungun974.com/melodink-server/internal/logger"
)

func (u *TrackUsecase) DiscoverNewTracks() error {
	tracks, err := u.trackRepository.GetAllTracks()
	if err != nil {
		return entities.NewInternalError(err)
	}

	files, err := u.trackStorage.ListAllAudios()
	if err != nil {
		return entities.NewInternalError(err)
	}

	jobs := make(chan string)

	var wg sync.WaitGroup

	for w := 0; w < 8; w++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for j := range jobs {
				u.discoverTrack(j, tracks)
			}
		}()
	}

	logger.MainLogger.Infof("Start checking %d files", len(files))

	for i, file := range files {
		logger.MainLogger.Infof("Process file %d/%d", i+1, len(files))

		jobs <- file
	}

	close(jobs)

	wg.Wait()

	logger.MainLogger.Infof("Track discover process finished")

	return nil
}

func (u *TrackUsecase) discoverTrack(file string, knowTracks []entities.Track) {
	for _, track := range knowTracks {
		if track.Path == file {
			return
		}
	}

	signature, err := makeFileSignature(file)
	if err != nil {
		logger.MainLogger.Errorf("Failed to make file signature \"%s\" : %v", file, err)
		return
	}

	for _, track := range knowTracks {
		if track.FileSignature == signature {
			if _, err := os.Stat(track.Path); errors.Is(err, os.ErrNotExist) {
				logger.DatabaseLogger.Warnf("Track \"%s\" file had disappeared but a new file with same signature have been found", track.Title)

				track.Path = file

				err = u.trackRepository.UpdateTrack(&track)
				if err != nil {
					logger.MainLogger.Errorf("Failed to change track path for \"%s\" : %v", track.Title, err)
					return
				}

				logger.DatabaseLogger.Warnf("Track \"%s\" path have been updated to \"%s\"", track.Title, file)
				return
			}
		}
	}

	newTrack, err := scanAudio(file)
	if err != nil {
		logger.MainLogger.Errorf("Failed to scan file \"%s\" : %v", file, err)
		return
	}

	err = u.trackRepository.CreateTrack(&newTrack)

	if err != nil {
		logger.MainLogger.Errorf("Failed to add to database new track \"%s\" : %v", newTrack.Title, err)
	}
}
