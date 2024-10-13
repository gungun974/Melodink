module github.com/gungun974/Melodink/server

go 1.22.5

replace git.sr.ht/~gungun974/go-musicbrainzws2 => go.uploadedlobster.com/musicbrainzws2 v0.9.1

replace gungun974/tag/tree/master => github.com/dhowden/tag v0.0.0-20240417053706-3d75831295e8

require (
	github.com/alfg/mp4 v0.0.0-20210728035756-55ea58c08aeb
	github.com/dhowden/tag v0.0.0-20240417053706-3d75831295e8
	github.com/gabriel-vasile/mimetype v1.4.5
	github.com/go-chi/chi/v5 v5.1.0
	github.com/go-chi/cors v1.2.1
	github.com/go-fingerprint/fingerprint v0.0.0-20140803133125-29397256b7ff
	github.com/go-fingerprint/gochroma v0.0.0-20211004000611-a294aa5ccab6
	github.com/go-resty/resty/v2 v2.13.1
	github.com/golang-jwt/jwt/v5 v5.2.1
	github.com/golang-migrate/migrate/v4 v4.17.1
	github.com/gungun974/validator v0.0.0-20240603034929-08715340e062
	github.com/jfreymuth/oggvorbis v1.0.5
	github.com/jmoiron/sqlx v1.4.0
	github.com/joho/godotenv v1.5.1
	github.com/mattn/go-sqlite3 v1.14.22
	github.com/mewkiz/flac v1.0.11
	github.com/pion/opus v0.0.0-20240826153031-e8536fe9e4ca
	github.com/sirupsen/logrus v1.9.3
	github.com/tcolgate/mp3 v0.0.0-20170426193717-e79c5a46d300
	go.uploadedlobster.com/musicbrainzws2 v0.9.1
	golang.org/x/crypto v0.25.0
	gopkg.in/vansante/go-ffprobe.v2 v2.2.0
)

require (
	github.com/google/uuid v1.6.0 // indirect
	github.com/hashicorp/errwrap v1.1.0 // indirect
	github.com/hashicorp/go-multierror v1.1.1 // indirect
	github.com/icza/bitio v1.1.0 // indirect
	github.com/jfreymuth/vorbis v1.0.2 // indirect
	github.com/lib/pq v1.10.9 // indirect
	github.com/mewkiz/pkg v0.0.0-20230226050401-4010bf0fec14 // indirect
	github.com/nyaruka/phonenumbers v1.3.1 // indirect
	go.uber.org/atomic v1.7.0 // indirect
	golang.org/x/net v0.27.0 // indirect
	golang.org/x/sys v0.22.0 // indirect
	golang.org/x/text v0.16.0 // indirect
	google.golang.org/protobuf v1.33.0 // indirect
)
