package storage_impl

import (
	"os"
	"path/filepath"
	"strings"

	"gungun974.com/melodink-server/internal/layers/domain/storage"
)

func NewTrackStorage() storage.TrackStorage {
	return &TrackStorageImpl{}
}

type TrackStorageImpl struct{}

func isAudioFile(path string) bool {
	ext := strings.ToLower(filepath.Ext(path))
	return ext == ".mp3" || ext == ".m4a" || ext == ".ogg" || ext == ".flac"
}

func (s *TrackStorageImpl) ListAllAudios() ([]string, error) {
	files := make([]string, 0)

	err := filepath.Walk("./data/tracks", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			if isAudioFile(path) {
				files = append(files, path)
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	return files, nil
}
