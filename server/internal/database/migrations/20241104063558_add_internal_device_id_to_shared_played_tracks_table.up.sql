DROP TABLE IF EXISTS shared_played_tracks;

CREATE TABLE shared_played_tracks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    internal_device_id INTEGER NOT NULL,

    user_id INTEGER NOT NULL,
    device_id TEXT NOT NULL,

    track_id INTEGER NOT NULL,

    start_at TIMESTAMP NOT NULL,
    finish_at TIMESTAMP NOT NULL,

    begin_at INTEGER NOT NULL,
    ended_at INTEGER NOT NULL,

    shuffle INTEGER NOT NULL,

    track_ended INTEGER NOT NULL, 

    shared_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_user_id_shared_played_tracks FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);


CREATE UNIQUE INDEX idx_shared_played_tracks_devices 
ON shared_played_tracks(internal_device_id, device_id);
