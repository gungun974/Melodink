package fr.gungun974.melodink

import MelodinkHostPlayerApi
import MelodinkHostPlayerApiInfo
import MelodinkHostPlayerLoopMode
import PlayerStatus
import android.os.Bundle
import androidx.annotation.NonNull
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import com.ryanheise.audioservice.AudioServiceActivity;
import io.flutter.embedding.engine.FlutterEngine

private class MelodinkHostPlayerApiImplementation @OptIn(UnstableApi::class) constructor
    (private val audioPlayer: AudioPlayer) : MelodinkHostPlayerApi {

    @OptIn(UnstableApi::class)
    override fun play() {
        audioPlayer.play()
    }

    @OptIn(UnstableApi::class)
    override fun pause() {
        audioPlayer.pause()
    }

    @OptIn(UnstableApi::class)
    override fun seek(positionMs: Long) {
        audioPlayer.seek(positionMs)
    }

    @OptIn(UnstableApi::class)
    override fun skipToNext() {
        audioPlayer.next()
    }

    @OptIn(UnstableApi::class)
    override fun skipToPrevious() {
        audioPlayer.prev()
    }

    @OptIn(UnstableApi::class)
    override fun setAudios(previousUrls: List<String>, nextUrls: List<String>) {
        audioPlayer.setAudios(previousUrls, nextUrls)
    }

    @OptIn(UnstableApi::class)
    override fun setLoopMode(loop: MelodinkHostPlayerLoopMode) {
        audioPlayer.setLoopMode(loop)
    }

    @OptIn(UnstableApi::class)
    override fun fetchStatus(): PlayerStatus {
        return PlayerStatus(
             playing = audioPlayer.isPlaying(),
         pos = audioPlayer.getCurrentTrackPos().toLong(),
         positionMs= audioPlayer.getCurrentPosition(),
         bufferedPositionMs = audioPlayer.getCurrentBufferedPosition(),
         state = audioPlayer.currentState,
        loop= audioPlayer.getCurrentLoopMode()

        )
    }

    @OptIn(UnstableApi::class)
    override fun setAuthToken(authToken: String) {
        audioPlayer.setAuthCookie(authToken)
    }
}

@UnstableApi
class MainActivity : AudioServiceActivity() {
    private var audioPlayer: AudioPlayer = AudioPlayer(this)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)


        audioPlayer.setup()
    }

    override fun onDestroy() {
        super.onDestroy()

        audioPlayer.destroy()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val pigeonFlutterApi = MelodinkHostPlayerApiInfo(flutterEngine.dartExecutor.binaryMessenger)

        audioPlayer.setOnTrackChangedListener { newTrackIndex ->
            pigeonFlutterApi.audioChanged(newTrackIndex.toLong()) {}
        }

        audioPlayer.setOnStateChangedListener { state ->
            pigeonFlutterApi.updateState(state) {}
        }


        val api = MelodinkHostPlayerApiImplementation(audioPlayer)
        MelodinkHostPlayerApi.setUp(flutterEngine.dartExecutor.binaryMessenger, api)
    }
}