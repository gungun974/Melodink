CREATE TABLE playlist_download (
    playlist_id INTERGER PRIMARY KEY,

    image_file TEXT NOT NULL,

    name TEXT NOT NULL,

    description TEXT NOT NULL,

    tracks TEXT NOT NULL
);
