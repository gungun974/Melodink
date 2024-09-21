CREATE TABLE track_download (
    track_id INTEGER PRIMARY KEY,
    audio_file TEXT NOT NULL,
    image_file TEXT,
    file_signature TEXT NOT NULL
);

INSERT INTO track_download (
    track_id, audio_file, image_file, file_signature
)
SELECT
    track_id,
    audio_file,
    image_file,
    file_signature
FROM track_download_new;

DROP TABLE track_download_new;

CREATE TABLE album_download (
    album_id TEXT PRIMARY KEY,
    image_file TEXT,
    name TEXT NOT NULL,
    album_artist TEXT NOT NULL,
    tracks TEXT NOT NULL
);

INSERT INTO album_download (
    album_id, image_file, name, album_artist, tracks
)
SELECT
    album_id,
    image_file,
    name,
    album_artist,
    tracks
FROM album_download_new;

DROP TABLE album_download_new;

CREATE TABLE playlist_download (
    playlist_id INTEGER PRIMARY KEY,
    image_file TEXT,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    tracks TEXT NOT NULL
);

INSERT INTO playlist_download (
    playlist_id, image_file, name, description, tracks
)
SELECT
    playlist_id,
    image_file,
    name,
    description,
    tracks
FROM playlist_download_new;

DROP TABLE playlist_download_new;

