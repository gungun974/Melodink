CREATE TABLE shared_played_tracks_new (
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
    created_at TIMESTAMP NOT NULL DEFAULT (ROUND((julianday('now') - 2440587.5) * 86400000))
);

INSERT INTO shared_played_tracks_new (
    id, 
    internal_device_id, 
    device_id, 
    track_id, 
    start_at, 
    finish_at, 
    begin_at, 
    ended_at, 
    shuffle, 
    track_ended, 
    shared_at, 
    created_at
) SELECT 
    id, 
    internal_device_id, 
    device_id, 
    track_id, 
    start_at, 
    finish_at, 
    begin_at, 
    ended_at, 
    shuffle, 
    track_ended, 
    shared_at, 
    (ROUND((julianday('now') - 2440587.5) * 86400000)) 
FROM shared_played_tracks;

DROP TABLE shared_played_tracks;
ALTER TABLE shared_played_tracks_new RENAME TO shared_played_tracks;
