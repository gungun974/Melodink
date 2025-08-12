CREATE TABLE sync (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    last_sync TIMESTAMP NOT NULL
);

