DROP TABLE IF EXISTS album_download;
DROP TABLE IF EXISTS playlist_download;

create table album_downloads (
    album_id INTEGER PRIMARY KEY,
    cover_file TEXT,
    cover_signature TEXT NOT NULL,
    partial_download BOOLEAN NOT NULL
);

create table playlist_downloads (
    playlist_id INTEGER PRIMARY KEY,
    cover_file TEXT,
    cover_signature TEXT NOT NULL
);
