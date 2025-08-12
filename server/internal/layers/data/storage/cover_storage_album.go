package storage

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"path"

	"github.com/gungun974/Melodink/server/internal/helpers"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
)

func (s *CoverStorage) getAlbumStorageDirectoryPath(album *entities.Album) string {
	directory := fmt.Sprintf(
		"%s/albums/%d/%s",
		COVER_STORAGE,
		*album.UserId,
		album.Id,
	)

	return directory
}

func (s *CoverStorage) UploadCustomAlbumCover(
	album *entities.Album,
	file io.Reader,
) error {
	directory := s.getAlbumStorageDirectoryPath(album)

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

	err = s.generateCompressedAlbumCovers(album)
	if err != nil {
		return err
	}

	return nil
}

func (s *CoverStorage) DuplicateAlbumCover(
	source *entities.Album,
	dest *entities.Album,
) error {
	sourceDirectory := s.getAlbumStorageDirectoryPath(source)
	destDirectory := s.getAlbumStorageDirectoryPath(dest)

	err := os.MkdirAll(destDirectory, 0o755)
	if err != nil {
		return err
	}

	sourceFile, err := os.Open(path.Join(sourceDirectory, "original"))
	if err != nil {
		return OriginalCoverNotFoundError
	}
	defer sourceFile.Close()

	originalFileLocation := helpers.SafeJoin(destDirectory, "original")

	destFile, err := os.Create(originalFileLocation)
	if err != nil {
		return err
	}
	defer destFile.Close()

	_, err = io.Copy(destFile, sourceFile)
	if err != nil {
		return err
	}

	err = s.generateCompressedAlbumCovers(dest)
	if err != nil {
		return err
	}

	return nil
}

func (s *CoverStorage) generateCompressedAlbumCovers(album *entities.Album) error {
	return s.generateCompressedCovers(s.getAlbumStorageDirectoryPath(album))
}

func (s *CoverStorage) GetCompressedAlbumCover(
	album *entities.Album,
	quality string,
) (bytes.Buffer, error) {
	return s.getCompressedCover(s.getAlbumStorageDirectoryPath(album), quality)
}

func (s *CoverStorage) GetOriginalAlbumCover(
	album *entities.Album,
) (bytes.Buffer, error) {
	return s.getOriginalCover(s.getAlbumStorageDirectoryPath(album))
}

func (s *CoverStorage) GetAlbumCoverSignature(
	album *entities.Album,
) string {
	return s.getCoverSignature(s.getAlbumStorageDirectoryPath(album))
}

func (s *CoverStorage) LoadAlbumCoverSignature(
	album *entities.Album,
) {
	album.CoverSignature = s.GetAlbumCoverSignature(album)

	if album.CoverSignature != "" {
		return
	}

	for _, track := range album.Tracks {
		album.CoverSignature = s.GetTrackCoverSignature(&track)

		if album.CoverSignature != "" {
			return
		}
	}
}

func (s *CoverStorage) RemoveAlbumCoverFiles(album *entities.Album) error {
	directory := s.getAlbumStorageDirectoryPath(album)

	err := os.RemoveAll(directory)
	if err != nil {
		return err
	}

	return nil
}
