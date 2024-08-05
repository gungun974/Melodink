package repository

import (
	"database/sql"
	"errors"

	data_models "github.com/gungun974/Melodink/server/internal/layers/data/models"
	"github.com/gungun974/Melodink/server/internal/layers/domain/entities"
	"github.com/gungun974/Melodink/server/internal/logger"
	"github.com/jmoiron/sqlx"
)

var UserNotFoundError = errors.New("User is not found")

func NewUserRepository(db *sqlx.DB) UserRepository {
	return UserRepository{
		Database: db,
	}
}

type UserRepository struct {
	Database *sqlx.DB
}

func (r *UserRepository) GetAllUsers() ([]entities.User, error) {
	m := data_models.UserModels{}

	err := r.Database.Select(&m, `
    SELECT id, name, email, created_at, updated_at
    FROM users
  `)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	return m.ToUsers(), nil
}

func (r *UserRepository) GetUserWithPasswordByEmail(
	email string,
) (*entities.User, error) {
	m := data_models.UserModel{}

	err := r.Database.Get(&m, `
    SELECT *
    FROM users
    WHERE email = $1
  `, email)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, UserNotFoundError
		}
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	user := m.ToUser()

	return &user, nil
}

func (r *UserRepository) GetUser(
	id int,
) (*entities.User, error) {
	m := data_models.UserModel{}

	err := r.Database.Get(&m, `
    SELECT id, name, email, created_at, updated_at
    FROM users
    WHERE id = $1
  `, id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, UserNotFoundError
		}
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	user := m.ToUser()

	return &user, nil
}

func (r *UserRepository) CreateUser(
	name string,
	email string,
	passwordHash string,
) (*entities.User, error) {
	m := data_models.UserModel{}

	err := r.Database.Get(
		&m,
		`
    INSERT INTO users (
      name,
      email,
      password
    ) VALUES (?, ?, ?)
    RETURNING id, name, email, created_at, updated_at
  `,
		name,
		email,
		passwordHash,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	user := m.ToUser()

	return &user, nil
}

func (r *UserRepository) UpdateUser(user *entities.User) error {
	m := data_models.UserModel{}

	err := r.Database.Get(&m, `
    UPDATE 
      users
    SET 
      name = ?, 
      email = ?,
      updated_at = CURRENT_TIMESTAMP
    WHERE 
      id = ?
    RETURNING id, name, email, created_at, updated_at
  `,
		user.Name,
		user.Email,
		user.Id,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	*user = m.ToUser()

	return nil
}

func (r *UserRepository) SetUserPassword(
	id int,
	passwordHash string,
) (*entities.User, error) {
	m := data_models.UserModel{}

	err := r.Database.Get(&m, `
    UPDATE 
      users
    SET 
      password = ?, 
      updated_at = CURRENT_TIMESTAMP
    WHERE 
      id = ?
    RETURNING id, name, email, created_at, updated_at
  `,
		id,
		passwordHash,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return nil, err
	}

	user := m.ToUser()

	return &user, nil
}

func (r *UserRepository) DeleteUser(user *entities.User) error {
	m := data_models.UserModel{}

	err := r.Database.Get(&m, `
    DELETE FROM
      user
    WHERE 
      id = ?
    RETURNING id, name, email, created_at, updated_at
  `,
		user.Id,
	)
	if err != nil {
		logger.DatabaseLogger.Error(err)
		return err
	}

	*user = m.ToUser()

	return nil
}
