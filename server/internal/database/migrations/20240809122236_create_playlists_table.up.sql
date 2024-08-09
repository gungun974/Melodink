CREATE TABLE playlists (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    user_id INTEGER,
  
    name TEXT NOT NULL,
    description TEXT NOT NULL,

    track_ids JSON NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,

    CONSTRAINT fk_user_id_tracks FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

