package internal

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/processors"
	"github.com/gungun974/Melodink/server/internal/layers/data/repositories"
	"github.com/gungun974/Melodink/server/internal/layers/data/scanners"
	"github.com/gungun974/Melodink/server/internal/layers/data/storages"
	album_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/album"
	artist_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/artist"
	config_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/config"
	playlist_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/playlist"
	shared_played_track_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/shared_played_track"
	sync_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/sync"
	track_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/track"
	user_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/user"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/controllers"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenters"
	"github.com/jmoiron/sqlx"
)

type Container struct {
	ConfigRepository repositories.ConfigRepository

	ConfigController            controllers.ConfigController
	UserController              controllers.UserController
	TrackController             controllers.TrackController
	PlaylistController          controllers.PlaylistController
	AlbumController             controllers.AlbumController
	ArtistController            controllers.ArtistController
	SharedPlayedTrackController controllers.SharedPlayedTrackController
	SyncController              controllers.SyncController
}

func NewContainer(db *sqlx.DB) Container {
	container := Container{}

	//! Repository

	container.ConfigRepository = repositories.NewConfigRepository(db)

	userRepository := repositories.NewUserRepository(db)
	albumRepository := repositories.NewAlbumRepository(db)
	trackRepository := repositories.NewTrackRepository(db)
	playlistRepository := repositories.NewPlaylistRepository(db, trackRepository)
	artistRepository := repositories.NewArtistRepository(db, trackRepository, albumRepository)
	sharedPlayedTrackRepository := repositories.NewSharedPlayedTrackRepository(db)

	//! Storage

	trackStorage := storages.NewTrackStorage()
	coverStorage := storages.NewCoverStorage()
	transcodeStorage := storages.NewTranscodeStorage()

	//! Scanner

	acoustIdScanner := scanners.NewAcoustIdScanner()
	musicBrainzScanner := scanners.NewMusicBrainzScanner()

	//! Processor

	transcodeProcessor := processors.NewTranscodeProcessor()

	//! Presenter

	userPresenter := presenters.NewUserPresenter()
	trackPresenter := presenters.NewTrackPresenter()
	playlistPresenter := presenters.NewPlaylistPresenter()
	albumPresenter := presenters.NewAlbumPresenter()
	artistPresenter := presenters.NewArtistPresenter()
	sharedPlayedTrackPresenter := presenters.NewSharedPlayedTrackPresenter()
	syncPresenter := presenters.NewSyncPresenter()

	//! Usecase

	configUsecase := config_usecase.NewConfigUsecase(
		container.ConfigRepository,
	)

	userUsecase := user_usecase.NewUserUsecase(
		userRepository,
		container.ConfigRepository,
		userPresenter,
	)

	trackUsecase := track_usecase.NewTrackUsecase(
		trackRepository,
		albumRepository,
		artistRepository,
		trackStorage,
		coverStorage,
		transcodeStorage,
		acoustIdScanner,
		musicBrainzScanner,
		transcodeProcessor,
		trackPresenter,
	)

	playlistUsecase := playlist_usecase.NewPlaylistUsecase(
		playlistRepository,
		trackRepository,
		coverStorage,
		playlistPresenter,
	)

	albumUsecase := album_usecase.NewAlbumUsecase(
		albumRepository,
		trackRepository,
		artistRepository,
		coverStorage,
		albumPresenter,
	)

	artistUsecase := artist_usecase.NewArtistUsecase(
		artistRepository,
		coverStorage,
		artistPresenter,
	)

	sharedPlayedTrackUsecase := shared_played_track_usecase.NewSharedPlayedTrackUsecase(
		sharedPlayedTrackRepository,
		sharedPlayedTrackPresenter,
	)

	syncUsecase := sync_usecase.NewSyncUsecase(
		trackRepository,
		albumRepository,
		artistRepository,
		playlistRepository,
		sharedPlayedTrackRepository,
		coverStorage,
		syncPresenter,
	)

	//! Controller

	container.ConfigController = controllers.NewConfigController(configUsecase)
	container.UserController = controllers.NewUserController(userUsecase)
	container.TrackController = controllers.NewTrackController(trackUsecase)
	container.PlaylistController = controllers.NewPlaylistController(playlistUsecase)
	container.AlbumController = controllers.NewAlbumController(albumUsecase)
	container.ArtistController = controllers.NewArtistController(artistUsecase)
	container.SharedPlayedTrackController = controllers.NewSharedPlayedTrackController(
		sharedPlayedTrackUsecase,
	)
	container.SyncController = controllers.NewSyncController(syncUsecase)

	return container
}
