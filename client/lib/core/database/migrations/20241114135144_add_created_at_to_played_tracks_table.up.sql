CREATE TABLE played_tracks_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    track_id INTEGER NOT NULL,
    start_at TIMESTAMP NOT NULL,
    finish_at TIMESTAMP NOT NULL,
    begin_at INTEGER NOT NULL,
    ended_at INTEGER NOT NULL,
    shuffle INTEGER NOT NULL,
    track_ended INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT (ROUND((julianday('now') - 2440587.5) * 86400000))
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
    created_at
)
SELECT 
    id,
    track_id,
    start_at,
    finish_at,
    begin_at,
    ended_at,
    shuffle,
    track_ended,
    (ROUND((julianday('now') - 2440587.5) * 86400000))
FROM played_tracks;

DROP TABLE played_tracks;
ALTER TABLE played_tracks_new RENAME TO played_tracks;
