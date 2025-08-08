ALTER TABLE album_artist
    ADD COLUMN artist_pos INTEGER;

ALTER TABLE track_artist
    ADD COLUMN artist_pos INTEGER;

ALTER TABLE track_album
    ADD COLUMN album_pos INTEGER;
