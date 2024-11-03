package internal

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/data/scanner"
	"github.com/gungun974/Melodink/server/internal/layers/data/storage"
	album_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/album"
	artist_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/artist"
	config_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/config"
	playlist_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/playlist"
	shared_played_track_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/shared_played_track"
	track_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/track"
	user_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/user"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/controller"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenter"
	"github.com/jmoiron/sqlx"
)

type Container struct {
	ConfigRepository repository.ConfigRepository

	ConfigController            controller.ConfigController
	UserController              controller.UserController
	TrackController             controller.TrackController
	PlaylistController          controller.PlaylistController
	AlbumController             controller.AlbumController
	ArtistController            controller.ArtistController
	SharedPlayedTrackController controller.SharedPlayedTrackController
}

func NewContainer(db *sqlx.DB) Container {
	container := Container{}

	//! Repository

	container.ConfigRepository = repository.NewConfigRepository(db)

	userRepository := repository.NewUserRepository(db)
	trackRepository := repository.NewTrackRepository(db)
	playlistRepository := repository.NewPlaylistRepository(db, trackRepository)
	albumRepository := repository.NewAlbumRepository(db, trackRepository)
	artistRepository := repository.NewArtistRepository(db, trackRepository, albumRepository)
	sharedPlayedTrackRepository := repository.NewSharedPlayedTrackRepository(db)

	//! Storage

	trackStorage := storage.NewTrackStorage()
	coverStorage := storage.NewCoverStorage()

	//! Scanner

	acoustIdScanner := scanner.NewAcoustIdScanner()
	musicBrainzScanner := scanner.NewMusicBrainzScanner()

	//! Presenter

	userPresenter := presenter.NewUserPresenter()
	trackPresenter := presenter.NewTrackPresenter()
	playlistPresenter := presenter.NewPlaylistPresenter()
	albumPresenter := presenter.NewAlbumPresenter()
	artistPresenter := presenter.NewArtistPresenter()
	sharedPlayedTrackPresenter := presenter.NewSharedPlayedTrackPresenter()

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
		trackStorage,
		coverStorage,
		acoustIdScanner,
		musicBrainzScanner,
		trackPresenter,
	)

	playlistUsecase := playlist_usecase.NewPlaylistUsecase(
		playlistRepository,
		trackRepository,
		coverStorage,
		playlistPresenter,
	)

	albumUsecase := album_usecase.NewAlbumUsecase(albumRepository, coverStorage, albumPresenter)

	artistUsecase := artist_usecase.NewArtistUsecase(
		artistRepository,
		coverStorage,
		artistPresenter,
	)

	sharedPlayedTrackUsecase := shared_played_track_usecase.NewSharedPlayedTrackUsecase(
		sharedPlayedTrackRepository,
		sharedPlayedTrackPresenter,
	)

	//! Controller

	container.ConfigController = controller.NewConfigController(configUsecase)
	container.UserController = controller.NewUserController(userUsecase)
	container.TrackController = controller.NewTrackController(trackUsecase)
	container.PlaylistController = controller.NewPlaylistController(playlistUsecase)
	container.AlbumController = controller.NewAlbumController(albumUsecase)
	container.ArtistController = controller.NewArtistController(artistUsecase)
	container.SharedPlayedTrackController = controller.NewSharedPlayedTrackController(
		sharedPlayedTrackUsecase,
	)

	return container
}
