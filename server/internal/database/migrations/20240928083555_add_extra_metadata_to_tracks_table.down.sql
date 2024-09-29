ALTER TABLE tracks
DROP COLUMN metadata_music_brainz_release_id;

ALTER TABLE tracks
DROP COLUMN metadata_music_brainz_track_id;

ALTER TABLE tracks
DROP COLUMN metadata_music_brainz_recording_id;

ALTER TABLE tracks
DROP COLUMN metadata_genres;

ALTER TABLE tracks
DROP COLUMN metadata_artists_roles;

ALTER TABLE tracks
ADD COLUMN metadata_genre TEXT;

ALTER TABLE tracks
ADD COLUMN metadata_acoust_id_fingerprint TEXT;

ALTER TABLE tracks
ADD COLUMN metadata_copyright TEXT;
