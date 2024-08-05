CREATE TABLE tracks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    user_id INTEGER,
  
    title TEXT NOT NULL,
    duration INTEGER,

    tags_format TEXT,
    file_type TEXT,

    path TEXT NOT NULL,
    file_signature TEXT NOT NULL,

    metadata_album TEXT,

    metadata_track_number INTEGER,
    metadata_total_tracks INTEGER,

    metadata_disc_number INTEGER,
    metadata_total_discs INTEGER,

    metadata_date TEXT,
    metadata_year INTEGER,

    metadata_genre TEXT,
    metadata_lyrics TEXT,
    metadata_comment TEXT,

    metadata_acoust_id TEXT,
    metadata_acoust_id_fingerprint TEXT,

    metadata_artist TEXT,
    metadata_album_artist TEXT,
    metadata_composer TEXT,

    metadata_copyright TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,

    CONSTRAINT fk_user_id_tracks FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);
