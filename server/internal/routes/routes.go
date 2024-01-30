package routes

import (
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"gungun974.com/melodink-server/internal"
)

func MainRouter(c internal.Container) *grpc.Server {
	s := grpc.NewServer()
	reflection.Register(s)

	TrackRouter(c, s)

	return s
}
