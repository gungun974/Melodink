DROP TABLE IF EXISTS shared_played_tracks;

CREATE TABLE played_tracks_new (
    internal_id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id INTEGER,

    track_id INTEGER NOT NULL,

    start_at TIMESTAMP NOT NULL,
    finish_at TIMESTAMP NOT NULL,

    begin_at INTEGER NOT NULL,
    ended_at INTEGER NOT NULL,

    shuffle INTEGER NOT NULL,

    track_ended INTEGER NOT NULL,

    shared_at TIMESTAMP,

    track_duration INTEGER NOT NULL,

    device_id TEXT
);

INSERT INTO played_tracks_new (
    internal_id,
    server_id,
    track_id,
    start_at,
    finish_at,
    begin_at,
    ended_at,
    shuffle,
    track_ended,
    shared_at,
    track_duration,
    device_id
)
SELECT
    id,
    NULL,
    track_id,
    start_at,
    finish_at,
    begin_at,
    ended_at,
    shuffle,
    track_ended,
    created_at,
    track_duration,
    NULL
FROM played_tracks;

DROP TABLE played_tracks;
ALTER TABLE played_tracks_new RENAME TO played_tracks;

CREATE UNIQUE INDEX idx_played_tracks_server_id ON played_tracks(server_id);
