package hls_usecase

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/processor"
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
)

type HlsUsecase struct {
	hlsProcessor    processor.HlsProcessor
	trackRepository repository.TrackRepository
}

func NewHlsUsecase(
	hlsProcessor processor.HlsProcessor,
	trackRepository repository.TrackRepository,
) HlsUsecase {
	return HlsUsecase{
		hlsProcessor,
		trackRepository,
	}
}
