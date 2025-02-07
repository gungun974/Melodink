ALTER TABLE tracks
ADD COLUMN transcoding_low_signature TEXT NOT NULL DEFAULT "";

ALTER TABLE tracks
ADD COLUMN transcoding_medium_signature TEXT NOT NULL DEFAULT "";

ALTER TABLE tracks
ADD COLUMN transcoding_high_signature TEXT NOT NULL DEFAULT "";
