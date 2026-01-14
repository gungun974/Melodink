package storages

import (
	"fmt"
	"os"
	"path"
)

func NewTranscodeStorage() TranscodeStorage {
	return TranscodeStorage{}
}

type TranscodeStorage struct{}

const (
	TRANSCODE_STORAGE = "./data/transcode/"
)

func (s *TranscodeStorage) GetTrackTranscodeDirectory(trackId int) (string, error) {
	idStr := fmt.Sprintf("%07d", trackId)

	n := len(idStr)

	partA := idStr[:n-4]
	partB := idStr[n-4 : n-2]
	partC := idStr[n-2:]

	directory := fmt.Sprintf("%s/%s/%s/%s", TRANSCODE_STORAGE, partA, partB, partC)

	err := os.MkdirAll(directory, 0o755)
	if err != nil {
		return "", err
	}

	return directory, nil
}

func (s *TranscodeStorage) DoTrackHasTranscodedQuality(trackId int, file string) bool {
	directory, err := s.GetTrackTranscodeDirectory(trackId)
	if err != nil {
		return false
	}

	_, err = os.Stat(path.Join(directory, file))
	return err == nil
}

func (s *TranscodeStorage) RemoveTrackTranscocdeDirectry(trackId int) error {
	directory, err := s.GetTrackTranscodeDirectory(trackId)
	if err != nil {
		return err
	}

	return os.RemoveAll(directory)
}
