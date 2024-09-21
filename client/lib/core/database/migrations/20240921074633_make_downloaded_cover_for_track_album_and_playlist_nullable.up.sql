CREATE TABLE track_download_new (
    track_id INTEGER PRIMARY KEY,
    audio_file TEXT NOT NULL,
    image_file TEXT,
    file_signature TEXT NOT NULL
);

INSERT INTO track_download_new (
    track_id, audio_file, image_file, file_signature
)
SELECT
    track_id,
    audio_file,
    image_file,
    file_signature
FROM track_download;

DROP TABLE track_download;

ALTER TABLE track_download_new RENAME TO track_download;

CREATE TABLE album_download_new (
    album_id TEXT PRIMARY KEY,
    image_file TEXT,
    name TEXT NOT NULL,
    album_artist TEXT NOT NULL,
    tracks TEXT NOT NULL
);

INSERT INTO album_download_new (
    album_id, image_file, name, album_artist, tracks
)
SELECT
    album_id,
    image_file,
    name,
    album_artist,
    tracks
FROM album_download;

DROP TABLE album_download;

ALTER TABLE album_download_new RENAME TO album_download;

CREATE TABLE playlist_download_new (
    playlist_id INTEGER PRIMARY KEY,
    image_file TEXT,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    tracks TEXT NOT NULL
);

INSERT INTO playlist_download_new (
    playlist_id, image_file, name, description, tracks
)
SELECT
    playlist_id,
    image_file,
    name,
    description,
    tracks
FROM playlist_download;

DROP TABLE playlist_download;

ALTER TABLE playlist_download_new RENAME TO playlist_download;
