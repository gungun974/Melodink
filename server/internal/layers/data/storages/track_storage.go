package storages

import (
	"errors"
	"fmt"
	"io"
	"math/rand"
	"os"
	"path"
	"strings"
	"time"

	"github.com/gabriel-vasile/mimetype"
	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

func NewTrackStorage() TrackStorage {
	return TrackStorage{}
}

type TrackStorage struct{}

const (
	AUDIOS_UPLOAD_STORAGE = "./data/uploads/"
	AUDIOS_STORAGE        = "./data/audios/"
)

func (s *TrackStorage) UploadAudioFile(userId int, file io.Reader) (string, error) {
	directory := fmt.Sprintf("%s/%d", AUDIOS_UPLOAD_STORAGE, userId)

	err := os.MkdirAll(directory, 0o755)
	if err != nil {
		return "", err
	}

	fileLocation := helpers.SafeJoin(
		directory,
		fmt.Sprintf("%d-%d", time.Now().UnixMicro(), rand.Int()),
	)

	destFile, err := os.Create(fileLocation)
	if err != nil {
		return "", err
	}
	defer destFile.Close()

	_, err = io.Copy(destFile, file)
	if err != nil {
		return "", err
	}

	mtype, err := mimetype.DetectFile(fileLocation)
	if err != nil {
		return fileLocation, nil
	}

	newFileLocation := fileLocation + strings.ReplaceAll(mtype.Extension(), ".mp4", ".m4a")

	err = os.Rename(fileLocation, newFileLocation)
	if err != nil {
		return fileLocation, nil
	}

	return newFileLocation, nil
}

func (s *TrackStorage) MoveAudioFile(track *entities.Track) error {
	idStr := fmt.Sprintf("%07d", track.Id)

	n := len(idStr)

	partA := idStr[:n-4]
	partB := idStr[n-4 : n-2]
	partC := idStr[n-2:]

	directory := fmt.Sprintf("%s/%d/%s/%s/%s", AUDIOS_STORAGE, *track.UserId, partA, partB, partC)

	err := os.MkdirAll(directory, 0o755)
	if err != nil {
		return err
	}

	filename := track.FileSignature

	var newFileLocation string

	for {
		targetFilename := filename
		newFileLocation = helpers.SafeJoin(directory, targetFilename) + path.Ext(track.Path)

		if _, err := os.Stat(newFileLocation); errors.Is(err, os.ErrNotExist) {
			break
		}

		filename += "_"
	}

	err = os.Rename(track.Path, newFileLocation)
	if err != nil {
		return err
	}

	track.Path = newFileLocation

	return nil
}

func (s *TrackStorage) RemoveAudioFile(track *entities.Track) error {
	err := os.Remove(track.Path)
	if err != nil {
		return err
	}

	track.Path = ""

	return nil
}
