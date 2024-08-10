package entities

type Artist struct {
	Id string

	UserId *int

	Name string

	Albums []Album

	AllTracks []Track
}
