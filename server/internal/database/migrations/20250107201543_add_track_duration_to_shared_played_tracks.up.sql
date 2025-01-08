ALTER TABLE shared_played_tracks
ADD track_duration INTEGER DEFAULT 0 NOT NULL;

UPDATE shared_played_tracks
SET track_duration = (
    SELECT t.duration
    FROM tracks t
    WHERE t.id = shared_played_tracks.track_id
)
WHERE EXISTS (
    SELECT 1
    FROM tracks t
    WHERE t.id = shared_played_tracks.track_id
);
