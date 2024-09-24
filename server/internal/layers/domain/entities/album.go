package entities

type Album struct {
	Id string

	UserId *int

	Name string

	AlbumArtists []string

	Tracks []Track
}
