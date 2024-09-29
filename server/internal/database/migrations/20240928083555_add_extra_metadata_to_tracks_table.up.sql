ALTER TABLE tracks
DROP COLUMN metadata_genre;

ALTER TABLE tracks
DROP COLUMN metadata_acoust_id_fingerprint;

ALTER TABLE tracks
DROP COLUMN metadata_copyright;

ALTER TABLE tracks
ADD COLUMN metadata_music_brainz_release_id TEXT;

ALTER TABLE tracks
ADD COLUMN metadata_music_brainz_track_id TEXT;

ALTER TABLE tracks
ADD COLUMN metadata_music_brainz_recording_id TEXT;

ALTER TABLE tracks
ADD COLUMN metadata_genres TEXT;

ALTER TABLE tracks
ADD COLUMN metadata_artists_roles TEXT;
