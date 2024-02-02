package track_usecase

import (
	"errors"
	"fmt"
	"os"
	"path"

	"gungun974.com/melodink-server/internal/layers/domain/entities"
	"gungun974.com/melodink-server/internal/layers/domain/repository"
	"gungun974.com/melodink-server/pb"
)

type FetchAudioStreamParams struct {
	TrackId       int
	StreamFormat  entities.AudioStreamFormat
	StreamQuality entities.AudioStreamQuality
}

func (u *TrackUsecase) FetchAudioStream(params FetchAudioStreamParams) (*pb.TrackFetchAudioStreamResponse, error) {
	track, err := u.trackRepository.GetTrack(params.TrackId)
	if err != nil {
		if errors.Is(err, repository.TrackNotFoundError) {
			return nil, entities.NewNotFoundError(
				fmt.Sprintf("Track \"%d\" not found", params.TrackId),
			)
		}
		return nil, entities.NewInternalError(err)
	}

	tempFolder := path.Join(os.TempDir(), "melodink/track")

	targetFolder := path.Join("/", fmt.Sprintf("%s_%s_%s", track.FileSignature, params.StreamFormat, params.StreamQuality))

	if params.StreamFormat == entities.AudioStreamFileFormat {
		targetFolder = path.Join("/", fmt.Sprintf("%s_%s", track.FileSignature, params.StreamFormat))
	}

	outputFolder := path.Join(tempFolder, targetFolder)

	var playableFile string

	switch params.StreamFormat {
	case entities.AudioStreamFileFormat:
		playableFile, err = u.audioProcessor.GenerateFile(track.Path, outputFolder)
		if err != nil {
			return nil, err
		}
	case entities.AudioStreamHLSFormat:
		playableFile, err = u.audioProcessor.GenerateHLS(track.Path, params.StreamQuality, outputFolder)
		if err != nil {
			return nil, err
		}
	case entities.AudioStreamDashFormat:
		playableFile, err = u.audioProcessor.GenerateDASH(track.Path, params.StreamQuality, outputFolder)
		if err != nil {
			return nil, err
		}
	}

	return &pb.TrackFetchAudioStreamResponse{
		Url: path.Join(targetFolder, playableFile),
	}, nil
}
