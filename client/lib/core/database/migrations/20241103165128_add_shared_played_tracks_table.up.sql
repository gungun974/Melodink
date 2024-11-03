CREATE TABLE shared_played_tracks (
    id INTEGER PRIMARY KEY,

    device_id TEXT NOT NULL,

    track_id INTEGER NOT NULL,

    start_at TIMESTAMP NOT NULL,
    finish_at TIMESTAMP NOT NULL,

    begin_at INTEGER NOT NULL,
    ended_at INTEGER NOT NULL,

    shuffle INTEGER NOT NULL,

    track_ended INTEGER NOT NULL,

    shared_at TIMESTAMP NOT NULL
);
