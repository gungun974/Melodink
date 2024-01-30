package routes

import (
	"context"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"
	"gungun974.com/melodink-server/internal"
	"gungun974.com/melodink-server/pb"
)

type trackServer struct {
	pb.UnimplementedTrackServer

	Container internal.Container
}

func (s *trackServer) ScanNewTracks(context.Context, *emptypb.Empty) (*emptypb.Empty, error) {
	err := s.Container.TrackController.DiscoverNewTracks()
	if err != nil {
		return nil, status.Error(
			codes.Unknown, err.Error(),
		)
	}

	return &emptypb.Empty{}, nil
}

func TrackRouter(c internal.Container, s *grpc.Server) {
	pb.RegisterTrackServer(s, &trackServer{
		Container: c,
	})
}
