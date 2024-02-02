package routes

import (
	"context"
	"net/http"

	"github.com/go-chi/chi/v5"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"
	"gungun974.com/melodink-server/internal"
	"gungun974.com/melodink-server/pb"
)

type trackServer struct {
	pb.UnimplementedTrackServiceServer

	Container internal.Container
}

func (s *trackServer) ScanNewTracks(context.Context, *emptypb.Empty) (*emptypb.Empty, error) {
	err := s.Container.TrackController.DiscoverNewTracks()
	if err != nil {
		return nil, handleGRPCError(err)
	}

	return &emptypb.Empty{}, nil
}

func (s *trackServer) ListAllTracks(_ *emptypb.Empty, stream pb.TrackService_ListAllTracksServer) error {
	tracks, err := s.Container.TrackController.GetAll()
	if err != nil {
		return handleGRPCError(err)
	}

	for {
		select {
		case <-stream.Context().Done():
			return status.Error(codes.Canceled, "Stream has ended")
		default:
			for _, track := range tracks.Tracks {
				err := stream.SendMsg(track)
				if err != nil {
					return status.Error(codes.Canceled, "Stream has ended")
				}
			}
			return nil
		}
	}
}

func TrackGRPCRouter(c internal.Container, s *grpc.Server) {
	pb.RegisterTrackServiceServer(s, &trackServer{
		Container: c,
	})
}

func TrackHTTPRouter(c internal.Container) http.Handler {
	router := chi.NewRouter()

	router.Get("/{id}/image", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")

		response, err := c.TrackController.GetCover(id)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	router.Get("/{id}/audio/{format}/{quality}", func(w http.ResponseWriter, r *http.Request) {
		id := chi.URLParam(r, "id")
		format := chi.URLParam(r, "format")
		quality := chi.URLParam(r, "quality")

		response, err := c.TrackController.FetchAudioStream(id, format, quality)
		if err != nil {
			handleHTTPError(err, w)
			return
		}

		response.WriteResponse(w, r)
	})

	return router
}
