ALTER TABLE tracks
ADD COLUMN sample_rate INTEGER;

ALTER TABLE tracks
ADD COLUMN bit_rate INTEGER;

ALTER TABLE tracks
ADD COLUMN bits_per_raw_sample INTEGER;
