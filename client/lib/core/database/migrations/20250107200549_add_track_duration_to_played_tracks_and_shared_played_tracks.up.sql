ALTER TABLE played_tracks
ADD track_duration INTEGER DEFAULT 0 NOT NULL;

ALTER TABLE shared_played_tracks
ADD track_duration INTEGER DEFAULT 0 NOT NULL;
