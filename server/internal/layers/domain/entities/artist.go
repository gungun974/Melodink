package entities

type Artist struct {
	Id int

	UserId *int

	Name string

	Albums        []Album
	AppearAlbums  []Album
	HasRoleAlbums []Album

	AllTracks        []Track
	AllAppearTracks  []Track
	AllHasRoleTracks []Track
}
