package hls_usecase

import (
	"path/filepath"
	"strconv"
	"strings"
)

func (u *HlsUsecase) CheckStreamSectionReady(
	trackId int,
	file string,
) bool {
	if filepath.Ext(file) != ".m4s" {
		return true
	}

	track, err := u.trackRepository.GetTrack(trackId)
	if err != nil {
		return false
	}

	lastUnderscoreIndex := strings.LastIndex(file, "_")
	lastDotIndex := strings.LastIndex(file, ".")

	name := file[:lastUnderscoreIndex]

	rawSection := file[lastUnderscoreIndex+1 : lastDotIndex]

	section, err := strconv.Atoi(rawSection)
	if err != nil {
		return false
	}

	return u.hlsProcessor.CheckStreamSectionReady(track, name, section)
}
