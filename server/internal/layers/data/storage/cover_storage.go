package storage

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"os"
	"path"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/pkgs/audioimage"
	"github.com/h2non/bimg"
)

func NewCoverStorage() CoverStorage {
	return CoverStorage{}
}

type CoverStorage struct{}

const (
	COVER_STORAGE = "./data/covers/"
)

var (
	OriginalCoverNotFoundError = errors.New("Orignal cover is not found")
	CoverQualityNotFoundError  = errors.New("Cover quality is not found")
)

func (s *CoverStorage) getTrackStorageDirectoryPath(track *entities.Track) string {
	idStr := fmt.Sprintf("%07d", track.Id)

	n := len(idStr)

	partA := idStr[:n-4]
	partB := idStr[n-4 : n-2]
	partC := idStr[n-2:]

	directory := fmt.Sprintf(
		"%s/tracks/%d/%s/%s/%s",
		COVER_STORAGE,
		*track.UserId,
		partA,
		partB,
		partC,
	)

	return directory
}

func (s *CoverStorage) GenerateTrackCoverFromAudioFile(track *entities.Track) error {
	directory := s.getTrackStorageDirectoryPath(track)

	err := os.MkdirAll(directory, 0o755)
	if err != nil {
		return err
	}

	image, err := audioimage.GetAudioImage(track.Path)
	if err != nil {
		return err
	}

	originalFileLocation := helpers.SafeJoin(directory, "original")

	file, err := os.Create(originalFileLocation)
	if err != nil {
		return err
	}
	defer file.Close()

	_, err = image.Data.WriteTo(file)
	if err != nil {
		return err
	}

	err = s.generateCompressedTrackCovers(track)
	if err != nil {
		return err
	}

	return nil
}

func (s *CoverStorage) generateCompressedTrackCovers(track *entities.Track) error {
	directory := s.getTrackStorageDirectoryPath(track)

	err := os.MkdirAll(directory, 0o755)
	if err != nil {
		return err
	}

	rawImage, err := bimg.Read(helpers.SafeJoin(directory, "original"))
	if err != nil {
		return err
	}

	for _, format := range []struct {
		size    int
		quality int
		name    string
	}{
		{size: 48, quality: 95, name: "small"},
		{size: 256, quality: 85, name: "medium"},
		{size: 1024, quality: 83, name: "high"},
	} {
		image, err := bimg.NewImage(rawImage).Process(bimg.Options{
			Type:    bimg.WEBP,
			Height:  format.size,
			Quality: format.quality,
		})
		if err != nil {
			return err
		}

		err = bimg.Write(path.Join(directory, format.name+".webp"), image)
		if err != nil {
			return err
		}
	}

	return nil
}

func (s *CoverStorage) GetCompressedTrackCover(
	track *entities.Track,
	quality string,
) (bytes.Buffer, error) {
	directory := s.getTrackStorageDirectoryPath(track)

	file, err := os.Open(path.Join(directory, quality+".webp"))
	if err != nil {
		return bytes.Buffer{},
			CoverQualityNotFoundError
	}
	defer file.Close()

	var buffer bytes.Buffer

	_, err = io.Copy(&buffer, file)
	if err != nil {
		return bytes.Buffer{}, err
	}

	return buffer, nil
}

func (s *CoverStorage) GetOriginalTrackCover(
	track *entities.Track,
) (bytes.Buffer, error) {
	directory := s.getTrackStorageDirectoryPath(track)

	file, err := os.Open(path.Join(directory, "original"))
	if err != nil {
		return bytes.Buffer{},
			OriginalCoverNotFoundError
	}
	defer file.Close()

	var buffer bytes.Buffer

	_, err = io.Copy(&buffer, file)
	if err != nil {
		return bytes.Buffer{}, err
	}

	return buffer, nil
}

func (s *CoverStorage) RemoveTrackCoverFiles(track *entities.Track) error {
	directory := s.getTrackStorageDirectoryPath(track)

	err := os.RemoveAll(directory)
	if err != nil {
		return err
	}

	return nil
}
