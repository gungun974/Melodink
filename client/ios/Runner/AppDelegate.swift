import AVFoundation
import Flutter
import UIKit

private class MelodinkHostApiImplementation: MelodinkHostPlayerApi {
    var player: AudioPlayer!

    init(flutterAPI: MelodinkHostPlayerApiInfo) {
        self.player = AudioPlayer(flutterAPI: flutterAPI)
    }

    func play() throws {
        player.play()
    }

    func pause() throws {
        player.pause()
    }

    func seek(positionMs: Int64) throws {
        player.seek(position_ms: Int(positionMs))
    }

    func skipToNext() throws {
        player.next()
    }

    func skipToPrevious() throws {
        player.prev()
    }

    func setAudios(previousUrls: [String], nextUrls: [String]) throws {
        player.setAudios(previousUrls: previousUrls, nextUrls: nextUrls)
    }

    func setLoopMode(loop: MelodinkHostPlayerLoopMode) throws {
        player.setLoopMode(loop: loop)
    }

    func fetchStatus() throws -> PlayerStatus {
        return PlayerStatus(
            playing: player.getCurrentPlaying(),
            pos: Int64(player.getCurrentTrackPos()),
            positionMs: Int64(player.getCurrentPosition()),
            bufferedPositionMs: Int64(player.getCurrentBufferedPosition()),
            state: player.getCurrentPlayerState(),
            loop: player.getCurrentLoopMode())
    }

    func setAuthToken(authToken: String) throws {
        player.setAuthToken(authToken: authToken)
    }

}

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Set the audio session category, mode, and options.
            try audioSession.setCategory(
                .playback, mode: .default,
                options: [.allowAirPlay, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set audio session category.")
        }

        let controller = window?.rootViewController as! FlutterViewController
        let api = MelodinkHostApiImplementation(
            flutterAPI: MelodinkHostPlayerApiInfo(
                binaryMessenger: controller.binaryMessenger))
        MelodinkHostPlayerApiSetup.setUp(
            binaryMessenger: controller.binaryMessenger, api: api)

        return super.application(
            application, didFinishLaunchingWithOptions: launchOptions)
    }
}
