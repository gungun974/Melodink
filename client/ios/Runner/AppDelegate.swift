import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
     var flutterAPI: MelodinkHostPlayerApiInfo?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        let controller = window?.rootViewController as! FlutterViewController


        self.flutterAPI = MelodinkHostPlayerApiInfo(
                binaryMessenger: controller.binaryMessenger)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil)

        return super.application(
            application, didFinishLaunchingWithOptions: launchOptions)
    }

    @objc func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey]
                as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return
        }

        switch type {
        case .began:
            DispatchQueue.main.async { [self] in
                flutterAPI?.externalPause { _ in
                }
            }

        case .ended:
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
            }

        @unknown default:
            break
        }
    }
}
