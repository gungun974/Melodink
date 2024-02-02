package entities

type AudioStreamFormat string

const (
	AudioStreamFileFormat AudioStreamFormat = "file"
	AudioStreamHLSFormat  AudioStreamFormat = "HLS"
	AudioStreamDashFormat AudioStreamFormat = "DASH"
)

type AudioStreamQuality string

const (
	AudioStreamLowQuality    AudioStreamQuality = "low"
	AudioStreamMediumQuality AudioStreamQuality = "medium"
	AudioStreamHighQuality   AudioStreamQuality = "high"
	AudioStreamMaxQuality    AudioStreamQuality = "max"
)
