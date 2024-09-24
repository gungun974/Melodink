package storage

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
	directory := fmt.Sprintf("%s/%d", AUDIOS_STORAGE, *track.UserId)

	if len(track.Metadata.Artists) > 0 && !helpers.IsEmptyOrWhitespace(track.Metadata.Artists[0]) {
		directory = helpers.SafeJoin(directory, track.Metadata.Artists[0])
	}

	if !helpers.IsEmptyOrWhitespace(track.Metadata.Album) {
		directory = helpers.SafeJoin(directory, track.Metadata.Album)
	}

	err := os.MkdirAll(directory, 0o755)
	if err != nil {
		return err
	}

	filename := track.FileSignature

	if !helpers.IsEmptyOrWhitespace(track.Title) {
		filename = track.Title
	}

	if track.Metadata.TrackNumber >= 0 {
		filename = fmt.Sprintf("%02d %s", track.Metadata.TrackNumber, filename)
	}

	var newFileLocation string

	for {
		targetFilename := filename + path.Ext(track.Path)
		newFileLocation = helpers.SafeJoin(directory, targetFilename)

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
