CREATE TABLE deleted_shared_played_tracks (
    id INTEGER PRIMARY KEY,
    deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

create table shared_played_tracks_dg_tmp
(
    id                 INTEGER
        primary key autoincrement,
    internal_device_id INTEGER             not null,
    user_id            INTEGER             not null
        constraint fk_user_id_shared_played_tracks
            references users
            on delete cascade,
    device_id          TEXT                not null,
    track_id           INTEGER             not null,
    start_at           TIMESTAMP           not null,
    finish_at          TIMESTAMP           not null,
    begin_at           INTEGER             not null,
    ended_at           INTEGER             not null,
    shuffle            INTEGER             not null,
    track_ended        INTEGER             not null,
    created_at         TIMESTAMP default CURRENT_TIMESTAMP,
    track_duration     INTEGER   default 0 not null,
    updated_at         TIMESTAMP
);

insert into shared_played_tracks_dg_tmp(id, internal_device_id, user_id, device_id, track_id, start_at, finish_at,
                                        begin_at, ended_at, shuffle, track_ended, created_at, track_duration)
select id,
       internal_device_id,
       user_id,
       device_id,
       track_id,
       start_at,
       finish_at,
       begin_at,
       ended_at,
       shuffle,
       track_ended,
       shared_at,
       track_duration
from shared_played_tracks;

drop table shared_played_tracks;

alter table shared_played_tracks_dg_tmp
    rename to shared_played_tracks;

create unique index idx_shared_played_tracks_devices
    on shared_played_tracks (internal_device_id, device_id);
