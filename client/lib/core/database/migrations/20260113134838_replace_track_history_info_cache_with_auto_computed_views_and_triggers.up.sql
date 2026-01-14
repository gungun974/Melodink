CREATE INDEX IF NOT EXISTS idx_played_tracks_track_id_finish_at
ON played_tracks(track_id, finish_at DESC);

CREATE INDEX IF NOT EXISTS idx_played_tracks_track_device_finish
ON played_tracks(track_id, device_id, finish_at DESC);

CREATE INDEX IF NOT EXISTS idx_played_tracks_finish_at
ON played_tracks(finish_at DESC);

CREATE TABLE IF NOT EXISTS validated_plays (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    track_id INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    segment_id INTEGER NOT NULL,
    start_at INTEGER NOT NULL,
    finish_at INTEGER NOT NULL,
    total_played_ms INTEGER NOT NULL,
    track_duration_ms INTEGER NOT NULL,
    UNIQUE(track_id, device_id, segment_id)
);

CREATE INDEX IF NOT EXISTS idx_validated_plays_track_finish
ON validated_plays(track_id, finish_at DESC);

CREATE INDEX IF NOT EXISTS idx_validated_plays_finish
ON validated_plays(finish_at DESC);

CREATE INDEX IF NOT EXISTS idx_validated_plays_track_device
ON validated_plays(track_id, device_id);

DROP TABLE IF EXISTS track_history_info_cache;

CREATE TABLE IF NOT EXISTS track_history_info (
    track_id INTEGER PRIMARY KEY,
    last_finished INTEGER,
    played_count INTEGER NOT NULL DEFAULT 0
);

CREATE TRIGGER IF NOT EXISTS trg_rebuild_validated_plays_after_insert
AFTER INSERT ON played_tracks
BEGIN
    DELETE FROM validated_plays
    WHERE track_id = NEW.track_id
      AND device_id = COALESCE(NEW.device_id, (SELECT value FROM config WHERE key = 'DEVICE_ID'));

    INSERT INTO validated_plays (track_id, device_id, segment_id, start_at, finish_at, total_played_ms, track_duration_ms)
    WITH current_device AS (
        SELECT COALESCE(NEW.device_id, (SELECT value FROM config WHERE key = 'DEVICE_ID')) AS id
    ),
    base_data AS (
        SELECT
            internal_id,
            track_id,
            COALESCE(device_id, (SELECT id FROM current_device)) AS effective_device_id,
            start_at,
            finish_at,
            begin_at,
            ended_at,
            track_duration
        FROM played_tracks
        WHERE track_id = NEW.track_id
          AND COALESCE(device_id, (SELECT id FROM current_device)) = (SELECT id FROM current_device)
    ),
    with_next AS (
        SELECT
            *,
            LEAD(begin_at, 1, begin_at) OVER (ORDER BY finish_at) AS next_begin_at,
            LEAD(track_id, 1, NULL) OVER (ORDER BY finish_at) AS next_track_id
        FROM base_data
    ),
    segmented AS (
        SELECT
            *,
            CASE
                WHEN next_begin_at >= MIN(track_duration * 0.2, 5000)
                     AND next_track_id = track_id
                THEN 0
                ELSE 1
            END AS is_new_segment
        FROM with_next
    ),
    numbered AS (
        SELECT
            *,
            SUM(is_new_segment) OVER (ORDER BY finish_at DESC) AS segment_number
        FROM segmented
    ),
    aggregated AS (
        SELECT
            track_id,
            effective_device_id AS device_id,
            segment_number AS segment_id,
            MIN(start_at) AS start_at,
            MAX(finish_at) AS finish_at,
            SUM(ended_at - begin_at) AS total_played_ms,
            MIN(track_duration) AS track_duration_ms
        FROM numbered
        GROUP BY segment_number
        HAVING SUM(ended_at - begin_at) > MIN(track_duration * 0.4, 30000)
    )
    SELECT * FROM aggregated;

    INSERT OR REPLACE INTO track_history_info (track_id, last_finished, played_count)
    SELECT
        NEW.track_id,
        MAX(finish_at),
        COUNT(*)
    FROM validated_plays
    WHERE track_id = NEW.track_id;
END;

CREATE TRIGGER IF NOT EXISTS trg_rebuild_validated_plays_after_update
AFTER UPDATE ON played_tracks
BEGIN
    DELETE FROM validated_plays
    WHERE track_id = OLD.track_id
      AND device_id = COALESCE(OLD.device_id, (SELECT value FROM config WHERE key = 'DEVICE_ID'));

    INSERT INTO validated_plays (track_id, device_id, segment_id, start_at, finish_at, total_played_ms, track_duration_ms)
    WITH current_device AS (
        SELECT COALESCE(OLD.device_id, (SELECT value FROM config WHERE key = 'DEVICE_ID')) AS id
    ),
    base_data AS (
        SELECT
            internal_id,
            track_id,
            COALESCE(device_id, (SELECT id FROM current_device)) AS effective_device_id,
            start_at,
            finish_at,
            begin_at,
            ended_at,
            track_duration
        FROM played_tracks
        WHERE track_id = OLD.track_id
          AND COALESCE(device_id, (SELECT id FROM current_device)) = (SELECT id FROM current_device)
    ),
    with_next AS (
        SELECT
            *,
            LEAD(begin_at, 1, begin_at) OVER (ORDER BY finish_at) AS next_begin_at,
            LEAD(track_id, 1, NULL) OVER (ORDER BY finish_at) AS next_track_id
        FROM base_data
    ),
    segmented AS (
        SELECT
            *,
            CASE
                WHEN next_begin_at >= MIN(track_duration * 0.2, 5000)
                     AND next_track_id = track_id
                THEN 0
                ELSE 1
            END AS is_new_segment
        FROM with_next
    ),
    numbered AS (
        SELECT
            *,
            SUM(is_new_segment) OVER (ORDER BY finish_at DESC) AS segment_number
        FROM segmented
    ),
    aggregated AS (
        SELECT
            track_id,
            effective_device_id AS device_id,
            segment_number AS segment_id,
            MIN(start_at) AS start_at,
            MAX(finish_at) AS finish_at,
            SUM(ended_at - begin_at) AS total_played_ms,
            MIN(track_duration) AS track_duration_ms
        FROM numbered
        GROUP BY segment_number
        HAVING SUM(ended_at - begin_at) > MIN(track_duration * 0.4, 30000)
    )
    SELECT * FROM aggregated WHERE EXISTS (SELECT 1 FROM base_data);

    DELETE FROM track_history_info WHERE track_id = OLD.track_id;
    INSERT INTO track_history_info (track_id, last_finished, played_count)
    SELECT OLD.track_id, MAX(finish_at), COUNT(*)
    FROM validated_plays
    WHERE track_id = OLD.track_id
    HAVING COUNT(*) > 0;

    DELETE FROM validated_plays
    WHERE track_id = NEW.track_id
      AND device_id = COALESCE(NEW.device_id, (SELECT value FROM config WHERE key = 'DEVICE_ID'))
      AND (OLD.track_id != NEW.track_id OR COALESCE(OLD.device_id, '') != COALESCE(NEW.device_id, ''));

    INSERT INTO validated_plays (track_id, device_id, segment_id, start_at, finish_at, total_played_ms, track_duration_ms)
    SELECT * FROM (
        WITH current_device AS (
            SELECT COALESCE(NEW.device_id, (SELECT value FROM config WHERE key = 'DEVICE_ID')) AS id
        ),
        base_data AS (
            SELECT
                internal_id,
                track_id,
                COALESCE(device_id, (SELECT id FROM current_device)) AS effective_device_id,
                start_at,
                finish_at,
                begin_at,
                ended_at,
                track_duration
            FROM played_tracks
            WHERE track_id = NEW.track_id
              AND COALESCE(device_id, (SELECT id FROM current_device)) = (SELECT id FROM current_device)
        ),
        with_next AS (
            SELECT
                *,
                LEAD(begin_at, 1, begin_at) OVER (ORDER BY finish_at) AS next_begin_at,
                LEAD(track_id, 1, NULL) OVER (ORDER BY finish_at) AS next_track_id
            FROM base_data
        ),
        segmented AS (
            SELECT
                *,
                CASE
                    WHEN next_begin_at >= MIN(track_duration * 0.2, 5000)
                         AND next_track_id = track_id
                    THEN 0
                    ELSE 1
                END AS is_new_segment
            FROM with_next
        ),
        numbered AS (
            SELECT
                *,
                SUM(is_new_segment) OVER (ORDER BY finish_at DESC) AS segment_number
            FROM segmented
        ),
        aggregated AS (
            SELECT
                track_id,
                effective_device_id AS device_id,
                segment_number AS segment_id,
                MIN(start_at) AS start_at,
                MAX(finish_at) AS finish_at,
                SUM(ended_at - begin_at) AS total_played_ms,
                MIN(track_duration) AS track_duration_ms
            FROM numbered
            GROUP BY segment_number
            HAVING SUM(ended_at - begin_at) > MIN(track_duration * 0.4, 30000)
        )
        SELECT * FROM aggregated WHERE EXISTS (SELECT 1 FROM base_data)
    )
    WHERE OLD.track_id != NEW.track_id OR COALESCE(OLD.device_id, '') != COALESCE(NEW.device_id, '');

    DELETE FROM track_history_info
    WHERE track_id = NEW.track_id AND OLD.track_id != NEW.track_id;
    INSERT INTO track_history_info (track_id, last_finished, played_count)
    SELECT NEW.track_id, MAX(finish_at), COUNT(*)
    FROM validated_plays
    WHERE track_id = NEW.track_id
      AND OLD.track_id != NEW.track_id
    HAVING COUNT(*) > 0;
END;

CREATE TRIGGER IF NOT EXISTS trg_rebuild_validated_plays_after_delete
AFTER DELETE ON played_tracks
BEGIN
    DELETE FROM validated_plays
    WHERE track_id = OLD.track_id
      AND device_id = COALESCE(OLD.device_id, (SELECT value FROM config WHERE key = 'DEVICE_ID'));

    INSERT INTO validated_plays (track_id, device_id, segment_id, start_at, finish_at, total_played_ms, track_duration_ms)
    WITH current_device AS (
        SELECT COALESCE(OLD.device_id, (SELECT value FROM config WHERE key = 'DEVICE_ID')) AS id
    ),
    base_data AS (
        SELECT
            internal_id,
            track_id,
            COALESCE(device_id, (SELECT id FROM current_device)) AS effective_device_id,
            start_at,
            finish_at,
            begin_at,
            ended_at,
            track_duration
        FROM played_tracks
        WHERE track_id = OLD.track_id
          AND COALESCE(device_id, (SELECT id FROM current_device)) = (SELECT id FROM current_device)
    ),
    with_next AS (
        SELECT
            *,
            LEAD(begin_at, 1, begin_at) OVER (ORDER BY finish_at) AS next_begin_at,
            LEAD(track_id, 1, NULL) OVER (ORDER BY finish_at) AS next_track_id
        FROM base_data
    ),
    segmented AS (
        SELECT
            *,
            CASE
                WHEN next_begin_at >= MIN(track_duration * 0.2, 5000)
                     AND next_track_id = track_id
                THEN 0
                ELSE 1
            END AS is_new_segment
        FROM with_next
    ),
    numbered AS (
        SELECT
            *,
            SUM(is_new_segment) OVER (ORDER BY finish_at DESC) AS segment_number
        FROM segmented
    ),
    aggregated AS (
        SELECT
            track_id,
            effective_device_id AS device_id,
            segment_number AS segment_id,
            MIN(start_at) AS start_at,
            MAX(finish_at) AS finish_at,
            SUM(ended_at - begin_at) AS total_played_ms,
            MIN(track_duration) AS track_duration_ms
        FROM numbered
        GROUP BY segment_number
        HAVING SUM(ended_at - begin_at) > MIN(track_duration * 0.4, 30000)
    )
    SELECT * FROM aggregated WHERE EXISTS (SELECT 1 FROM base_data);

    DELETE FROM track_history_info WHERE track_id = OLD.track_id;
    INSERT INTO track_history_info (track_id, last_finished, played_count)
    SELECT OLD.track_id, MAX(finish_at), COUNT(*)
    FROM validated_plays
    WHERE track_id = OLD.track_id
    HAVING COUNT(*) > 0;
END;

INSERT INTO validated_plays (track_id, device_id, segment_id, start_at, finish_at, total_played_ms, track_duration_ms)
WITH base_data AS (
    SELECT
        internal_id,
        track_id,
        device_id AS effective_device_id,
        start_at,
        finish_at,
        begin_at,
        ended_at,
        track_duration
    FROM played_tracks
    WHERE device_id IS NOT NULL
),
with_next AS (
    SELECT
        *,
        LEAD(begin_at, 1, begin_at) OVER (
            PARTITION BY track_id, effective_device_id
            ORDER BY finish_at
        ) AS next_begin_at,
        LEAD(track_id, 1, NULL) OVER (
            PARTITION BY track_id, effective_device_id
            ORDER BY finish_at
        ) AS next_track_id
    FROM base_data
),
segmented AS (
    SELECT
        *,
        CASE
            WHEN next_begin_at >= MIN(track_duration * 0.2, 5000)
                 AND next_track_id = track_id
            THEN 0
            ELSE 1
        END AS is_new_segment
    FROM with_next
),
numbered AS (
    SELECT
        *,
        SUM(is_new_segment) OVER (
            PARTITION BY track_id, effective_device_id
            ORDER BY finish_at DESC
        ) AS segment_number
    FROM segmented
),
aggregated AS (
    SELECT
        track_id,
        effective_device_id AS device_id,
        segment_number AS segment_id,
        MIN(start_at) AS start_at,
        MAX(finish_at) AS finish_at,
        SUM(ended_at - begin_at) AS total_played_ms,
        MIN(track_duration) AS track_duration_ms
    FROM numbered
    GROUP BY track_id, effective_device_id, segment_number
    HAVING SUM(ended_at - begin_at) > MIN(track_duration * 0.4, 30000)
)
SELECT * FROM aggregated;

INSERT INTO validated_plays (track_id, device_id, segment_id, start_at, finish_at, total_played_ms, track_duration_ms)
WITH current_device AS (
    SELECT value AS id FROM config WHERE key = 'DEVICE_ID'
),
base_data AS (
    SELECT
        internal_id,
        track_id,
        (SELECT id FROM current_device) AS effective_device_id,
        start_at,
        finish_at,
        begin_at,
        ended_at,
        track_duration
    FROM played_tracks
    WHERE device_id IS NULL
),
with_next AS (
    SELECT
        *,
        LEAD(begin_at, 1, begin_at) OVER (
            PARTITION BY track_id
            ORDER BY finish_at
        ) AS next_begin_at,
        LEAD(track_id, 1, NULL) OVER (
            PARTITION BY track_id
            ORDER BY finish_at
        ) AS next_track_id
    FROM base_data
),
segmented AS (
    SELECT
        *,
        CASE
            WHEN next_begin_at >= MIN(track_duration * 0.2, 5000)
                 AND next_track_id = track_id
            THEN 0
            ELSE 1
        END AS is_new_segment
    FROM with_next
),
numbered AS (
    SELECT
        *,
        SUM(is_new_segment) OVER (
            PARTITION BY track_id
            ORDER BY finish_at DESC
        ) AS segment_number
    FROM segmented
),
aggregated AS (
    SELECT
        track_id,
        effective_device_id AS device_id,
        segment_number AS segment_id,
        MIN(start_at) AS start_at,
        MAX(finish_at) AS finish_at,
        SUM(ended_at - begin_at) AS total_played_ms,
        MIN(track_duration) AS track_duration_ms
    FROM numbered
    GROUP BY track_id, segment_number
    HAVING SUM(ended_at - begin_at) > MIN(track_duration * 0.4, 30000)
)
SELECT * FROM aggregated
WHERE NOT EXISTS (
    SELECT 1 FROM validated_plays vp
    WHERE vp.track_id = aggregated.track_id
      AND vp.device_id = aggregated.device_id
      AND vp.segment_id = aggregated.segment_id
);

INSERT INTO track_history_info (track_id, last_finished, played_count)
SELECT
    track_id,
    MAX(finish_at) AS last_finished,
    COUNT(*) AS played_count
FROM validated_plays
GROUP BY track_id;
