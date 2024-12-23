CREATE TABLE track_score (
    user_id INTEGER NOT NULL,
    track_id INTEGER NOT NULL,
    score FLOAT NOT NULL,
    PRIMARY KEY (user_id, track_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE
);
