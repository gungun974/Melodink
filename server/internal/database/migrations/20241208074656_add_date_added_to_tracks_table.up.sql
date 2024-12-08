create table tracks_tmp
(
    id                                 INTEGER
        primary key autoincrement,
    user_id                            INTEGER
        constraint fk_user_id_tracks
            references users
            on delete set null,
    title                              TEXT not null,
    duration                           INTEGER,
    tags_format                        TEXT,
    file_type                          TEXT,
    path                               TEXT not null,
    file_signature                     TEXT not null,
    metadata_album                     TEXT,
    metadata_track_number              INTEGER,
    metadata_total_tracks              INTEGER,
    metadata_disc_number               INTEGER,
    metadata_total_discs               INTEGER,
    metadata_date                      TEXT,
    metadata_year                      INTEGER,
    metadata_lyrics                    TEXT,
    metadata_comment                   TEXT,
    metadata_acoust_id                 TEXT,
    metadata_artists                   TEXT,
    metadata_album_artists             TEXT,
    metadata_composer                  TEXT,
    created_at                         TIMESTAMP default CURRENT_TIMESTAMP,
    updated_at                         TIMESTAMP,
    metadata_music_brainz_release_id   TEXT,
    metadata_music_brainz_track_id     TEXT,
    metadata_music_brainz_recording_id TEXT,
    metadata_genres                    TEXT,
    metadata_artists_roles             TEXT,
    sample_rate                        INTEGER,
    bit_rate                           INTEGER,
    bits_per_raw_sample                INTEGER,
    date_added                         TIMESTAMP default CURRENT_TIMESTAMP
);

insert into tracks_tmp(id, user_id, title, duration, tags_format, file_type, path, file_signature, metadata_album,
                          metadata_track_number, metadata_total_tracks, metadata_disc_number, metadata_total_discs,
                          metadata_date, metadata_year, metadata_lyrics, metadata_comment, metadata_acoust_id,
                          metadata_artists, metadata_album_artists, metadata_composer, created_at, updated_at,
                          metadata_music_brainz_release_id, metadata_music_brainz_track_id,
                          metadata_music_brainz_recording_id, metadata_genres, metadata_artists_roles, sample_rate,
                          bit_rate, bits_per_raw_sample)
select id,
       user_id,
       title,
       duration,
       tags_format,
       file_type,
       path,
       file_signature,
       metadata_album,
       metadata_track_number,
       metadata_total_tracks,
       metadata_disc_number,
       metadata_total_discs,
       metadata_date,
       metadata_year,
       metadata_lyrics,
       metadata_comment,
       metadata_acoust_id,
       metadata_artists,
       metadata_album_artists,
       metadata_composer,
       created_at,
       updated_at,
       metadata_music_brainz_release_id,
       metadata_music_brainz_track_id,
       metadata_music_brainz_recording_id,
       metadata_genres,
       metadata_artists_roles,
       sample_rate,
       bit_rate,
       bits_per_raw_sample
from tracks;

drop table tracks;

alter table tracks_tmp
    rename to tracks;

UPDATE tracks SET date_added = created_at;
