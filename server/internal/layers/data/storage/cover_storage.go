package storage

import (
	"bytes"
	"crypto/md5"
	"encoding/hex"
	"errors"
	"io"
	"os"
	"path"

	"github.com/gungun974/Melodink/server/internal/helpers"
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

func (s *CoverStorage) generateCompressedCovers(directory string) error {
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
		{size: 256, quality: 70, name: "small"},
		{size: 512, quality: 75, name: "medium"},
		{size: 1024, quality: 83, name: "high"},
	} {

		image := bimg.NewImage(rawImage)
		size, err := image.Size()
		if err != nil {
			return err
		}

		if size.Height <= format.size {
			newImage, err := image.Process(bimg.Options{
				Type:          bimg.WEBP,
				Quality:       format.quality,
				Interlace:     true,
				StripMetadata: true,
			})
			if err != nil {
				return err
			}

			err = bimg.Write(path.Join(directory, format.name+".webp"), newImage)
			if err != nil {
				return err
			}

			continue
		}

		newImage, err := image.Process(bimg.Options{
			Type:          bimg.WEBP,
			Height:        format.size,
			Quality:       format.quality,
			Interlace:     true,
			StripMetadata: true,
		})
		if err != nil {
			return err
		}

		err = bimg.Write(path.Join(directory, format.name+".webp"), newImage)
		if err != nil {
			return err
		}
	}

	return nil
}

func (s *CoverStorage) getCompressedCover(
	directory string,
	quality string,
) (bytes.Buffer, error) {
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

func (s *CoverStorage) getOriginalCover(
	directory string,
) (bytes.Buffer, error) {
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

func (s *CoverStorage) getCoverSignature(
	directory string,
) string {
	file, err := os.Open(path.Join(directory, "original"))
	if err != nil {
		return ""
	}

	defer file.Close()

	hash := md5.New()
	_, err = io.Copy(hash, file)
	if err != nil {
		return ""
	}

	return hex.EncodeToString(hash.Sum(nil))
}
