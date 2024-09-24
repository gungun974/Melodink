ALTER TABLE tracks RENAME COLUMN metadata_artists TO metadata_artist;
ALTER TABLE tracks RENAME COLUMN metadata_album_artists TO metadata_album_artist;

UPDATE tracks SET metadata_artist = NULL, metadata_album_artist = NULL;
