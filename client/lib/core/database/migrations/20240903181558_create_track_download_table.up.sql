CREATE TABLE track_download (
    track_id INTEGER PRIMARY KEY,

    audio_file TEXT NOT NULL,
    image_file TEXT NOT NULL,

    file_signature TEXT NOT NULL
);
