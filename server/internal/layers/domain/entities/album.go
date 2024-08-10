package entities

type Album struct {
	Id string

	UserId *int

	Name string

	AlbumArtist string

	Tracks []Track
}
