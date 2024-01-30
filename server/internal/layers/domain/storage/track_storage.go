package storage

type TrackStorage interface {
	ListAllAudios() ([]string, error)
}
