package entities

type Album struct {
	Id int

	UserId *int

	Name string

	Artists []Artist

	Tracks []Track

	CoverSignature string
}
