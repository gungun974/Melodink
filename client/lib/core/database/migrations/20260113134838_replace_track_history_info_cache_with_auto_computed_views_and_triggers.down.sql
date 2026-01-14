DROP TRIGGER IF EXISTS trg_rebuild_validated_plays_after_insert;
DROP TRIGGER IF EXISTS trg_rebuild_validated_plays_after_update;
DROP TRIGGER IF EXISTS trg_rebuild_validated_plays_after_delete;

DROP TABLE IF EXISTS track_history_info;
DROP TABLE IF EXISTS validated_plays;

DROP INDEX IF EXISTS idx_validated_plays_track_device;
DROP INDEX IF EXISTS idx_validated_plays_finish;
DROP INDEX IF EXISTS idx_validated_plays_track_finish;

DROP INDEX IF EXISTS idx_played_tracks_finish_at;
DROP INDEX IF EXISTS idx_played_tracks_track_device_finish;
DROP INDEX IF EXISTS idx_played_tracks_track_id_finish_at;

CREATE TABLE IF NOT EXISTS track_history_info_cache (
    track_id INTEGER PRIMARY KEY,
    last_finished INTEGER,
    played_count INTEGER NOT NULL DEFAULT 0
);
