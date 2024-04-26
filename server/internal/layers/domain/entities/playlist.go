package entities

type PlaylistType string

const (
	AlbumPlaylistType  PlaylistType = "Album"
	ArtistPlaylistType PlaylistType = "Artist"
	CustomPlaylistType PlaylistType = "Custom"
)

type Playlist struct {
	Id string

	Name        string
	Description string

	AlbumArtist string

	Type PlaylistType

	Tracks []Track
}
