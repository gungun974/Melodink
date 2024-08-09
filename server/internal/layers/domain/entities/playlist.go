package entities

type PlaylistType string

type Playlist struct {
	Id int

	UserId *int

	Name        string
	Description string

	Tracks []Track
}
