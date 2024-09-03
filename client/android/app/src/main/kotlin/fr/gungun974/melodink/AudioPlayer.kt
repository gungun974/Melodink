package fr.gungun974.melodink

import MelodinkHostPlayerLoopMode
import MelodinkHostPlayerProcessingState
import android.content.Context
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.extractor.DefaultExtractorsFactory

@UnstableApi
class AudioPlayer(private val context: Context) {
    private lateinit var exoPlayer: ExoPlayer

    private var onTrackChangedListener: ((Int) -> Unit)? = null

    private var onStateChangedListener: ((MelodinkHostPlayerProcessingState) -> Unit)? = null

    var dontSendAudioChanged = false;

    var currentState = MelodinkHostPlayerProcessingState.IDLE

    @OptIn(UnstableApi::class)
    fun setup() {
        exoPlayer = ExoPlayer.Builder(context)
            .build()

        exoPlayer.addListener(object : Player.Listener {
            override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
                super.onMediaItemTransition(mediaItem, reason)
                val newTrackIndex = getCurrentTrackPos()

                if (dontSendAudioChanged) {
                    return
                }

                onTrackChangedListener?.invoke(newTrackIndex)
            }


            override fun onPlaybackStateChanged(playbackState: Int) {
                when (playbackState) {
                    Player.STATE_IDLE -> {
                        currentState = MelodinkHostPlayerProcessingState.IDLE
                        onStateChangedListener?.invoke(MelodinkHostPlayerProcessingState.IDLE)
                    }

                    Player.STATE_BUFFERING -> {
                        currentState = MelodinkHostPlayerProcessingState.BUFFERING
                        onStateChangedListener?.invoke(MelodinkHostPlayerProcessingState.BUFFERING)
                    }

                    Player.STATE_READY -> {
                        currentState = MelodinkHostPlayerProcessingState.READY
                        onStateChangedListener?.invoke(MelodinkHostPlayerProcessingState.READY)
                    }

                    Player.STATE_ENDED -> {
                        currentState = MelodinkHostPlayerProcessingState.COMPLETED
                        onStateChangedListener?.invoke(MelodinkHostPlayerProcessingState.COMPLETED)
                    }
                }
            }
        })

        exoPlayer.playWhenReady = true
    }


    fun setOnTrackChangedListener(listener: (Int) -> Unit) {
        onTrackChangedListener = listener
    }

    fun setOnStateChangedListener(listener: (MelodinkHostPlayerProcessingState) -> Unit) {
        onStateChangedListener = listener
    }

    fun destroy() {
        exoPlayer.release()
    }

    fun play() {
        exoPlayer.playWhenReady = true
    }

    fun pause() {
        exoPlayer.playWhenReady = false
    }

    fun next() {
        if (exoPlayer.hasNextMediaItem()) {
            exoPlayer.seekToNextMediaItem()
        }
    }

    fun prev() {
        if (exoPlayer.hasPreviousMediaItem()) {
            exoPlayer.seekToPreviousMediaItem()
        }
    }

    fun seek(positionMs: Long) {
        exoPlayer.seekTo(positionMs)
    }


    @OptIn(UnstableApi::class)
    fun getCurrentTrackPos(): Int {
        return exoPlayer.currentMediaItemIndex
    }

    fun getPlaylistLength(): Int {
        return exoPlayer.mediaItemCount
    }

    fun getCurrentPosition(): Long {
        return exoPlayer.currentPosition
    }

    fun getCurrentBufferedPosition(): Long {
        return exoPlayer.bufferedPosition
    }

    fun isPlaying(): Boolean {
        return exoPlayer.isPlaying
    }

    @OptIn(UnstableApi::class)
    fun setAudios(previousUrls: List<String>, nextUrls: List<String>) {
        dontSendAudioChanged = true

        val currentMedia = exoPlayer.currentMediaItem

        if (previousUrls.isNotEmpty() && currentMedia != null && currentMedia.localConfiguration?.uri.toString() == previousUrls.last()) {

            var hasChange = previousUrls.size + nextUrls.size != exoPlayer.mediaItemCount

            if (!hasChange) {
                for ((index, url) in (previousUrls + nextUrls).withIndex()) {
                    if (exoPlayer.getMediaItemAt(index).localConfiguration?.uri.toString() != url) {
                        hasChange = true
                        break
                    }
                }
            }

            if (hasChange) {

                if (exoPlayer.currentMediaItemIndex + 1 <= exoPlayer.mediaItemCount) {
                    exoPlayer.removeMediaItems(
                        exoPlayer.currentMediaItemIndex + 1,
                        exoPlayer.mediaItemCount
                    )
                }

                if (0 <= exoPlayer.currentMediaItemIndex) {
                    exoPlayer.removeMediaItems(0, exoPlayer.currentMediaItemIndex)
                }

                exoPlayer.addMediaSources(nextUrls.map { buildMediaSource(it) })
                exoPlayer.addMediaSources(0, previousUrls.dropLast(1).map { buildMediaSource(it) })
            }
        } else {
            exoPlayer.setMediaSources(previousUrls.map { buildMediaSource(it) } + nextUrls.map {
                buildMediaSource(
                    it
                )
            }, previousUrls.size - 1, 0)

        }

        currentState = MelodinkHostPlayerProcessingState.READY
        onStateChangedListener?.invoke(MelodinkHostPlayerProcessingState.READY)


        exoPlayer.prepare()

        dontSendAudioChanged = false
    }

    fun debug() {
        print("---------------\n");
        for (i in 0 until getPlaylistLength()) {
            val result = exoPlayer.getMediaItemAt(i).localConfiguration?.uri.toString()
            print("$i : ${result}\n");
        }
    }

    private var currentAuthCookie = ""

    fun setAuthCookie(cookie: String) {
        currentAuthCookie = cookie
    }


    @OptIn(UnstableApi::class)
    private fun buildMediaSource(url: String): MediaSource {

        val extractorsFactory =
         DefaultExtractorsFactory().setConstantBitrateSeekingEnabled(true);

        return DefaultMediaSourceFactory(DefaultHttpDataSource.Factory().apply {
                    setDefaultRequestProperties(
                        mapOf(
                            "Cookie" to currentAuthCookie
                        )
                    )
                },extractorsFactory )
            .createMediaSource(MediaItem.fromUri(url))
    }

    fun setLoopMode(loop: MelodinkHostPlayerLoopMode) {
       if (loop == MelodinkHostPlayerLoopMode.NONE) {
           exoPlayer.repeatMode = Player.REPEAT_MODE_OFF
           return
       }
        if (loop == MelodinkHostPlayerLoopMode.ONE) {
            exoPlayer.repeatMode = Player.REPEAT_MODE_ONE
            return
        }
        exoPlayer.repeatMode = Player.REPEAT_MODE_ALL
    }

    fun getCurrentLoopMode(): MelodinkHostPlayerLoopMode {
        if (exoPlayer.repeatMode == Player.REPEAT_MODE_OFF) {
            return MelodinkHostPlayerLoopMode.NONE
        }
        if (exoPlayer.repeatMode == Player.REPEAT_MODE_ONE) {
            return MelodinkHostPlayerLoopMode.ONE
        }
        return MelodinkHostPlayerLoopMode.ALL
    }
}