CREATE TABLE tracks (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,

    title TEXT NOT NULL,
    duration INTEGER NOT NULL,
    tags_format TEXT NOT NULL,
    file_type TEXT NOT NULL,
    file_signature TEXT NOT NULL,
    cover_signature TEXT NOT NULL,
    track_number INTEGER NOT NULL,
    disc_number INTEGER NOT NULL,

    metadata_total_tracks INTEGER NOT NULL,
    metadata_total_discs INTEGER NOT NULL,
    metadata_date TEXT NOT NULL,
    metadata_year INTEGER NOT NULL,
    metadata_genres JSON NOT NULL,
    metadata_lyrics TEXT NOT NULL,
    metadata_comment TEXT NOT NULL,
    metadata_acoust_id TEXT NOT NULL,
    metadata_music_brainz_release_id TEXT NOT NULL,
    metadata_music_brainz_track_id TEXT NOT NULL,
    metadata_music_brainz_recording_id TEXT NOT NULL,
    metadata_composer TEXT NOT NULL,

    sample_rate INTEGER NOT NULL,
    bit_rate INTEGER,
    bits_per_raw_sample INTEGER,

    score REAL NOT NULL,

    date_added TIMESTAMP NOT NULL
);

CREATE TABLE albums (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,

    name TEXT NOT NULL,

    cover_signature TEXT NOT NULL
);

CREATE TABLE artists (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,

    name TEXT NOT NULL
);

CREATE TABLE playlists (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,

    name TEXT NOT NULL,
    description TEXT NOT NULL,
    tracks JSON NOT NULL,

    cover_signature TEXT NOT NULL
);

CREATE TABLE album_artist (
    album_id INTEGER NOT NULL,
    artist_id INTEGER NOT NULL,
    artist_pos INTEGER,
    PRIMARY KEY (album_id, artist_id),
    FOREIGN KEY (album_id) REFERENCES albums(id) ON DELETE CASCADE,
    FOREIGN KEY (artist_id) REFERENCES artists(id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE track_artist (
    artist_id INTEGER NOT NULL,
    track_id INTEGER NOT NULL,
    artist_pos INTEGER,
    PRIMARY KEY (artist_id, track_id),
    FOREIGN KEY (artist_id) REFERENCES artists(id) ON DELETE CASCADE,
    FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE track_album (
    album_id INTEGER NOT NULL,
    track_id INTEGER NOT NULL,
    album_pos INTEGER,
    PRIMARY KEY (album_id, track_id),
    FOREIGN KEY (album_id) REFERENCES albums(id) ON DELETE CASCADE,
    FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE INDEX track_album_track_album_idx ON track_album(track_id, album_id);
CREATE INDEX track_album_album_track_idx ON track_album(album_id, track_id);

CREATE INDEX track_artist_track_artist_idx ON track_artist(track_id, artist_id);
CREATE INDEX track_artist_artist_track_idx ON track_artist(artist_id, track_id);

CREATE INDEX album_artist_album_artist_idx ON album_artist(album_id, artist_id);
CREATE INDEX album_artist_artist_album_idx ON album_artist(artist_id, album_id);
