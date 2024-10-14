package database

import (
	"embed"
	"errors"
	"time"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/sqlite3"
	"github.com/golang-migrate/migrate/v4/source/iofs"
	"github.com/gungun974/Melodink/server/internal/logger"

	"github.com/jmoiron/sqlx"
	_ "github.com/mattn/go-sqlite3" // Import sqlite3 driver
)

//go:embed migrations/*.sql
var fs embed.FS

func Connect() *sqlx.DB {
	db, err := sqlx.Connect("sqlite3", "./data/melodink.db")
	if err != nil {
		logger.DatabaseLogger.Fatalln(err)
	}

	logger.DatabaseLogger.Info("📀 Database connection established successfully!")

	return db
}

func getMigrateInstance(db *sqlx.DB) *migrate.Migrate {
	d, err := iofs.New(fs, "migrations")
	if err != nil {
		logger.DatabaseLogger.Fatalf("Unable to open migrations embedded directory: %v", err)
	}

	driver, err := sqlite3.WithInstance(db.DB, &sqlite3.Config{})
	if err != nil {
		logger.DatabaseLogger.Fatalf("Unable to get migrate instance: %v", err)
	}

	m, err := migrate.NewWithInstance(
		"iofs",
		d,
		"sqlite3",
		driver,
	)
	if err != nil {
		logger.DatabaseLogger.Fatalf("Unable to get migrate instance: %v", err)
	}

	return m
}

func MigrateCurrent(db *sqlx.DB) {
	m := getMigrateInstance(db)

	version, dirty, err := m.Version()

	if errors.Is(err, migrate.ErrNilVersion) {
		logger.DatabaseLogger.Info("No current migration are applied")
		return
	}

	if err != nil {
		logger.DatabaseLogger.Fatalf("Migration version failed: %v", err)
	}

	if dirty {
		logger.DatabaseLogger.Warnf("Current migration is %v and dirty", version)
		return
	}
	logger.DatabaseLogger.Infof("Current migration is %v", version)
}

func MigrateUp(db *sqlx.DB) {
	m := getMigrateInstance(db)

	logger.DatabaseLogger.Info("Start migrations up")

	start := time.Now()

	if err := m.Up(); err != nil && !errors.Is(err, migrate.ErrNoChange) {
		logger.DatabaseLogger.Fatalf("Migration up failed: %v", err)
	}

	duration := time.Since(start)

	logger.DatabaseLogger.Infof("Finish making migrations in %s", duration)

	MigrateCurrent(db)
}

func MigrateDown(db *sqlx.DB) {
	m := getMigrateInstance(db)

	logger.DatabaseLogger.Info("Start migrations down")

	start := time.Now()

	if err := m.Steps(-1); err != nil && !errors.Is(err, migrate.ErrNoChange) {
		logger.DatabaseLogger.Fatalf("Migration down failed: %v", err)
	}

	duration := time.Since(start)

	logger.DatabaseLogger.Infof("Finish making migrations in %s", duration)

	MigrateCurrent(db)
}

func MigrateVersion(db *sqlx.DB, version int) {
	m := getMigrateInstance(db)

	logger.DatabaseLogger.Info("Start migration force")

	start := time.Now()

	if err := m.Force(version); err != nil && !errors.Is(err, migrate.ErrNoChange) {
		logger.DatabaseLogger.Fatalf("Migration force failed: %v", err)
	}

	duration := time.Since(start)

	logger.DatabaseLogger.Infof("Finish forcing migration in %s", duration)

	MigrateCurrent(db)
}
