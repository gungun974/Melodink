create table album_artist_dg_tmp
(
    album_id   INTEGER not null
        references albums
            on delete cascade,
    artist_id  INTEGER not null
        references artists
            on delete cascade,
    artist_pos INTEGER,
    primary key (album_id, artist_id)
)
    without rowid;

insert into album_artist_dg_tmp(album_id, artist_id, artist_pos)
select album_id, artist_id, artist_pos
from album_artist;

drop table album_artist;

alter table album_artist_dg_tmp
    rename to album_artist;

create table track_album_dg_tmp
(
    album_id  INTEGER not null
        references albums
            on delete cascade,
    track_id  INTEGER not null
        references tracks
            on delete cascade,
    album_pos INTEGER,
    primary key (album_id, track_id)
)
    without rowid;

insert into track_album_dg_tmp(album_id, track_id, album_pos)
select album_id, track_id, album_pos
from track_album;

drop table track_album;

alter table track_album_dg_tmp
    rename to track_album;


create table track_artist_dg_tmp
(
    artist_id  INTEGER not null
        references artists
            on delete cascade,
    track_id   INTEGER not null
        references tracks
            on delete cascade,
    artist_pos INTEGER,
    primary key (artist_id, track_id)
)
    without rowid;

insert into track_artist_dg_tmp(artist_id, track_id, artist_pos)
select artist_id, track_id, artist_pos
from track_artist;

drop table track_artist;

alter table track_artist_dg_tmp
    rename to track_artist;

CREATE INDEX track_album_track_album_idx ON track_album(track_id, album_id);
CREATE INDEX track_album_album_track_idx ON track_album(album_id, track_id);

CREATE INDEX track_artist_track_artist_idx ON track_artist(track_id, artist_id);
CREATE INDEX track_artist_artist_track_idx ON track_artist(artist_id, track_id);

CREATE INDEX album_artist_album_artist_idx ON album_artist(album_id, artist_id);
CREATE INDEX album_artist_artist_album_idx ON album_artist(artist_id, album_id);

