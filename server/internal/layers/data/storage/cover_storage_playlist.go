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

func (s *CoverStorage) getPlaylistStorageDirectoryPath(playlist *entities.Playlist) string {
	idStr := fmt.Sprintf("%07d", playlist.Id)

	n := len(idStr)

	partA := idStr[:n-4]
	partB := idStr[n-4 : n-2]
	partC := idStr[n-2:]

	directory := fmt.Sprintf(
		"%s/playlists/%d/%s/%s/%s",
		COVER_STORAGE,
		*playlist.UserId,
		partA,
		partB,
		partC,
	)

	return directory
}

func (s *CoverStorage) UploadCustomPlaylistCover(
	playlist *entities.Playlist,
	file io.Reader,
) error {
	directory := s.getPlaylistStorageDirectoryPath(playlist)

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

	err = s.generateCompressedPlaylistCovers(playlist)
	if err != nil {
		return err
	}

	return nil
}

func (s *CoverStorage) DuplicatePlaylistCover(
	source *entities.Playlist,
	dest *entities.Playlist,
) error {
	sourceDirectory := s.getPlaylistStorageDirectoryPath(source)
	destDirectory := s.getPlaylistStorageDirectoryPath(dest)

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

	err = s.generateCompressedPlaylistCovers(dest)
	if err != nil {
		return err
	}

	return nil
}

func (s *CoverStorage) generateCompressedPlaylistCovers(playlist *entities.Playlist) error {
	return s.generateCompressedCovers(s.getPlaylistStorageDirectoryPath(playlist))
}

func (s *CoverStorage) GetCompressedPlaylistCover(
	playlist *entities.Playlist,
	quality string,
) (bytes.Buffer, error) {
	return s.getCompressedCover(s.getPlaylistStorageDirectoryPath(playlist), quality)
}

func (s *CoverStorage) GetOriginalPlaylistCover(
	playlist *entities.Playlist,
) (bytes.Buffer, error) {
	return s.getOriginalCover(s.getPlaylistStorageDirectoryPath(playlist))
}

func (s *CoverStorage) GetPlaylistCoverSignature(
	playlist *entities.Playlist,
) string {
	return s.getCoverSignature(s.getPlaylistStorageDirectoryPath(playlist))
}

func (s *CoverStorage) LoadPlaylistCoverSignature(
	playlist *entities.Playlist,
) {
	playlist.CoverSignature = s.GetPlaylistCoverSignature(playlist)

	if playlist.CoverSignature != "" {
		return
	}

	for _, track := range playlist.Tracks {
		playlist.CoverSignature = s.GetTrackCoverSignature(&track)

		if playlist.CoverSignature != "" {
			return
		}
	}
}

func (s *CoverStorage) RemovePlaylistCoverFiles(playlist *entities.Playlist) error {
	directory := s.getPlaylistStorageDirectoryPath(playlist)

	err := os.RemoveAll(directory)
	if err != nil {
		return err
	}

	return nil
}
