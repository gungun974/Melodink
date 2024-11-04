create table played_tracks_dg_tmp
(
    id          INTEGER
        primary key autoincrement,
    track_id    INTEGER   not null,
    start_at    TIMESTAMP not null,
    finish_at   TIMESTAMP not null,
    begin_at    INTEGER   not null,
    ended_at    INTEGER   not null,
    shuffle     INTEGER   not null,
    track_ended INTEGER   not null
);

insert into played_tracks_dg_tmp(id, track_id, start_at, finish_at, begin_at, ended_at, shuffle, track_ended)
select id,
       track_id,
       start_at,
       finish_at,
       begin_at,
       ended_at,
       shuffle,
       track_ended
from played_tracks;

drop table played_tracks;

alter table played_tracks_dg_tmp
    rename to played_tracks;
