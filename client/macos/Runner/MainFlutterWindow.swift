import Cocoa
import FlutterMacOS

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

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)
        
        RegisterGeneratedPlugins(registry: flutterViewController)
        
        let api = MelodinkHostApiImplementation(
            flutterAPI: MelodinkHostPlayerApiInfo(
                binaryMessenger: flutterViewController.engine.binaryMessenger))
        MelodinkHostPlayerApiSetup.setUp(
            binaryMessenger: flutterViewController.engine.binaryMessenger, api: api)
        
        
        super.awakeFromNib()
    }
}
