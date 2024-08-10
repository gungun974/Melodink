package internal

import (
	"github.com/gungun974/Melodink/server/internal/layers/data/repository"
	"github.com/gungun974/Melodink/server/internal/layers/data/storage"
	album_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/album"
	playlist_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/playlist"
	track_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/track"
	user_usecase "github.com/gungun974/Melodink/server/internal/layers/domain/usecases/user"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/controller"
	"github.com/gungun974/Melodink/server/internal/layers/presentation/presenter"
	"github.com/jmoiron/sqlx"
)

type Container struct {
	UserController     controller.UserController
	TrackController    controller.TrackController
	PlaylistController controller.PlaylistController
	AlbumController    controller.AlbumController
}

func NewContainer(db *sqlx.DB) Container {
	container := Container{}

	//! Repository

	userRepository := repository.NewUserRepository(db)
	trackRepository := repository.NewTrackRepository(db)
	playlistRepository := repository.NewPlaylistRepository(db, trackRepository)
	albumRepository := repository.NewAlbumRepository(db, trackRepository)

	//! Storage

	trackStorage := storage.NewTrackStorage()

	//! Presenter

	userPresenter := presenter.NewUserPresenter()
	trackPresenter := presenter.NewTrackPresenter()
	playlistPresenter := presenter.NewPlaylistPresenter()
	albumPresenter := presenter.NewAlbumPresenter()

	//! Usecase

	userUsecase := user_usecase.NewUserUsecase(
		userRepository,
		userPresenter,
	)

	trackUsecase := track_usecase.NewTrackUsecase(
		trackRepository,
		trackStorage,
		trackPresenter,
	)

	playlistUsecase := playlist_usecase.NewPlaylistUsecase(
		playlistRepository,
		trackRepository,
		playlistPresenter,
	)

	albumUsecase := album_usecase.NewAlbumUsecase(albumRepository, albumPresenter)

	//! Controller

	container.UserController = controller.NewUserController(userUsecase)
	container.TrackController = controller.NewTrackController(trackUsecase)
	container.PlaylistController = controller.NewPlaylistController(playlistUsecase)
	container.AlbumController = controller.NewAlbumController(albumUsecase)

	return container
}
