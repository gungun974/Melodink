package storages

import (
	"bytes"
	"fmt"
	"io"
	"os"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/pkgs/audioimage"
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

func (s *CoverStorage) UploadCustomTrackCover(track *entities.Track, file io.Reader) error {
	directory := s.getTrackStorageDirectoryPath(track)

	err := os.MkdirAll(directory, 0o755)
	if err != nil {
		return err
	}

	originalFileLocation := helpers.SafeJoin(directory, "original")

	destFile, err := os.Create(originalFileLocation)
	if err != nil {
		return err
	}
	defer destFile.Close()

	_, err = io.Copy(destFile, file)
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
	return s.generateCompressedCovers(s.getTrackStorageDirectoryPath(track))
}

func (s *CoverStorage) GetCompressedTrackCover(
	track *entities.Track,
	quality string,
) (bytes.Buffer, error) {
	return s.getCompressedCover(s.getTrackStorageDirectoryPath(track), quality)
}

func (s *CoverStorage) GetOriginalTrackCover(
	track *entities.Track,
) (bytes.Buffer, error) {
	return s.getOriginalCover(s.getTrackStorageDirectoryPath(track))
}

func (s *CoverStorage) GetTrackCoverSignature(
	track *entities.Track,
) string {
	return s.getCoverSignature(s.getTrackStorageDirectoryPath(track))
}

func (s *CoverStorage) RemoveTrackCoverFiles(track *entities.Track) error {
	directory := s.getTrackStorageDirectoryPath(track)

	err := os.RemoveAll(directory)
	if err != nil {
		return err
	}

	return nil
}
