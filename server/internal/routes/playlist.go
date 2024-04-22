package routes

import (
	"context"

	"google.golang.org/grpc"
	"google.golang.org/protobuf/types/known/emptypb"
	"gungun974.com/melodink-server/internal"
	"gungun974.com/melodink-server/pb"
)

type playlistServer struct {
	pb.UnimplementedPlaylistServiceServer

	Container internal.Container
}

func (s *playlistServer) ListAllAlbums(context.Context, *emptypb.Empty) (*pb.PlaylistList, error) {
	playlists, err := s.Container.PlaylistController.ListAllAlbums()
	if err != nil {
		return nil, handleGRPCError(err)
	}

	return playlists, nil
}

func PlaylistGRPCRouter(c internal.Container, s *grpc.Server) {
	pb.RegisterPlaylistServiceServer(s, &playlistServer{
		Container: c,
	})
}
