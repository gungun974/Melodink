package helpers

import (
	"path/filepath"
	"strings"
)

var windowsInvalidChars = []string{"<", ">", ":", "\"", "/", "\\", "|", "?", "*"}

var linuxInvalidChars = []string{"/"}

const replacementChar = "_"

func replaceInvalidChars(name string, invalidChars []string) string {
	for _, char := range invalidChars {
		name = strings.ReplaceAll(name, char, replacementChar)
	}
	return name
}

func SafeJoin(basePath, addPath string) string {
	cleanedPath := filepath.Clean(addPath)

	for strings.HasPrefix(cleanedPath, "..") {
		cleanedPath = strings.TrimPrefix(cleanedPath, "..")
		cleanedPath = strings.TrimPrefix(cleanedPath, string(filepath.Separator))
	}

	cleanedPath = replaceInvalidChars(cleanedPath, windowsInvalidChars)
	cleanedPath = replaceInvalidChars(cleanedPath, linuxInvalidChars)

	fullPath := filepath.Join(basePath, cleanedPath)

	return fullPath
}
