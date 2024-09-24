ALTER TABLE album_download RENAME COLUMN album_artists TO album_artist;

UPDATE album_download SET album_artist = ""

