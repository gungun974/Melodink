ALTER TABLE album_download RENAME COLUMN album_artist TO album_artists;

UPDATE album_download SET album_artists = '[]';
