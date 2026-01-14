package repositories

import (
	"database/sql"
	"errors"

	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/jmoiron/sqlx"
)

var ConfigKeyNotFoundError = errors.New("Config Key is not found")

func NewConfigRepository(
	db *sqlx.DB,
) ConfigRepository {
	return ConfigRepository{
		Database: db,
	}
}

type ConfigRepository struct {
	Database *sqlx.DB
}

func (r *ConfigRepository) SetString(
	key string,
	value string,
) error {
	_, err := r.Database.Exec(
		`
      INSERT OR REPLACE INTO config (key, value) 
      VALUES (?, ?);
    `,
		key, value,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	return nil
}

func (r *ConfigRepository) GetString(
	key string,
) (string, error) {
	var value string
	err := r.Database.QueryRow("SELECT value FROM config WHERE key = ?", key).Scan(&value)
	if err != nil {
		if err == sql.ErrNoRows {
			return "", ConfigKeyNotFoundError
		}
		return "", err
	}
	return value, nil
}
