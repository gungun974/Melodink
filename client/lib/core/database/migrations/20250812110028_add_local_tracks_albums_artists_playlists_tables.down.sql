DROP INDEX IF EXISTS track_album_track_album_idx;
DROP INDEX IF EXISTS track_album_album_track_idx;

DROP INDEX IF EXISTS track_artist_track_artist_idx;
DROP INDEX IF EXISTS track_artist_artist_track_idx;

DROP INDEX IF EXISTS album_artist_album_artist_idx;
DROP INDEX IF EXISTS album_artist_artist_album_idx;

DROP TABLE IF EXISTS track_album;
DROP TABLE IF EXISTS track_artist;
DROP TABLE IF EXISTS album_artist;

DROP TABLE IF EXISTS playlists;
DROP TABLE IF EXISTS artists;
DROP TABLE IF EXISTS albums;
DROP TABLE IF EXISTS tracks;
