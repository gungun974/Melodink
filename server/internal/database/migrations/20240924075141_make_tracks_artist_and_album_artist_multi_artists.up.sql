ALTER TABLE tracks RENAME COLUMN metadata_artist TO metadata_artists;
ALTER TABLE tracks RENAME COLUMN metadata_album_artist TO metadata_album_artists;

UPDATE tracks SET metadata_artists = NULL, metadata_album_artists = NULL;
