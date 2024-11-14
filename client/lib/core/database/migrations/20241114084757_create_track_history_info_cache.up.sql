CREATE TABLE track_history_info_cache (
    track_id INTEGER PRIMARY KEY,
    last_finished DATETIME,
    played_count INTEGER DEFAULT 0,

    updated_at TIMESTAMP
);
