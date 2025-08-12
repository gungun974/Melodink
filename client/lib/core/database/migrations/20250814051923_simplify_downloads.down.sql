DROP TABLE IF EXISTS album_downloads;
DROP TABLE IF EXISTS playlist_downloads;

create table album_download
(
    album_id        TEXT
        primary key,
    image_file      TEXT,
    name            TEXT               not null,
    album_artists   TEXT               not null,
    tracks          TEXT               not null,
    download_tracks INTEGER default 1  not null,
    cover_signature TEXT    default '' not null
);

create table playlist_download
(
    playlist_id     INTEGER
        primary key,
    image_file      TEXT,
    name            TEXT            not null,
    description     TEXT            not null,
    tracks          TEXT            not null,
    cover_signature TEXT default '' not null
);
