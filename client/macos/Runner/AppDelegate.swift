import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    override func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        return true
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication)
        -> Bool
    {
        return true
    }

    var statusItem: NSStatusItem?

    override func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            if let originalImage = NSImage(named: NSImage.Name("AppIcon")) {
                let grayscaleImage =
                    self.whitenedImage(image: originalImage) ?? originalImage
                button.image = grayscaleImage
                button.imageScaling = .scaleProportionallyDown
            }
            button.action = #selector(toggleWindow(_:))
            button.target = self
        }

        super.applicationDidFinishLaunching(aNotification)
    }

    @objc func toggleWindow(_ sender: AnyObject) {
        guard let window = NSApp.windows.first else { return }

        NSApp.activate(ignoringOtherApps: true)
        window.orderFrontRegardless()
    }

    func whitenedImage(image: NSImage) -> NSImage? {
        guard let tiffData = image.tiffRepresentation,
            let bitmapImage = NSBitmapImageRep(data: tiffData),
            let ciImage = CIImage(bitmapImageRep: bitmapImage)
        else {
            return nil
        }

        let grayscale = CIFilter(
            name: "CIPhotoEffectNoir", parameters: [kCIInputImageKey: ciImage])
        guard let grayImage = grayscale?.outputImage else { return nil }

        let colorControls = CIFilter(name: "CIColorControls")!
        colorControls.setValue(grayImage, forKey: kCIInputImageKey)
        colorControls.setValue(0.0, forKey: kCIInputSaturationKey)
        colorControls.setValue(1.0, forKey: kCIInputBrightnessKey)
        colorControls.setValue(0.4, forKey: kCIInputContrastKey)

        guard let outputImage = colorControls.outputImage else { return nil }

        let rep = NSCIImageRep(ciImage: outputImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }
}
