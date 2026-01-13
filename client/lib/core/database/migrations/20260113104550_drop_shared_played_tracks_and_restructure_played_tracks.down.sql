DROP INDEX IF EXISTS idx_played_tracks_server_id;

CREATE TABLE played_tracks_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    track_id INTEGER NOT NULL,

    start_at TIMESTAMP NOT NULL,
    finish_at TIMESTAMP NOT NULL,

    begin_at INTEGER NOT NULL,
    ended_at INTEGER NOT NULL,

    shuffle INTEGER NOT NULL,

    track_ended INTEGER NOT NULL,

    created_at TIMESTAMP NOT NULL,

    track_duration INTEGER NOT NULL
);

INSERT INTO played_tracks_new (
    id,
    track_id,
    start_at,
    finish_at,
    begin_at,
    ended_at,
    shuffle,
    track_ended,
    created_at,
    track_duration
)
SELECT
    internal_id,
    track_id,
    start_at,
    finish_at,
    begin_at,
    ended_at,
    shuffle,
    track_ended,
    shared_at,
    track_duration
FROM played_tracks;

DROP TABLE played_tracks;
ALTER TABLE played_tracks_new RENAME TO played_tracks;

CREATE TABLE shared_played_tracks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    internal_device_id INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    track_id INTEGER NOT NULL,
    start_at TIMESTAMP NOT NULL,
    finish_at TIMESTAMP NOT NULL,
    begin_at INTEGER NOT NULL,
    ended_at INTEGER NOT NULL,
    shuffle INTEGER NOT NULL,
    track_ended INTEGER NOT NULL,
    shared_at INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT (ROUND((julianday('now') - 2440587.5) * 86400000)),
    track_duration INTEGER NOT NULL
);
