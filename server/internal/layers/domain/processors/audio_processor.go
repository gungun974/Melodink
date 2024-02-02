package processor

import "gungun974.com/melodink-server/internal/layers/domain/entities"

type AudioProcessor interface {
	GenerateFile(source string, destination string) (string, error)

	GenerateHLS(source string, quality entities.AudioStreamQuality, destination string) (string, error)

	GenerateDASH(source string, quality entities.AudioStreamQuality, destination string) (string, error)
}
