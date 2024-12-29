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
            withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            if let originalImage = NSImage(named: NSImage.Name("AppIcon")) {
                let resizedImage = resizeImageToFitStatusBar(
                    image: originalImage, height: NSStatusBar.system.thickness)
                let grayscaleImage =
                    self.whitenedImage(image: resizedImage) ?? resizedImage
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

    func resizeImageToFitStatusBar(image: NSImage, height: CGFloat) -> NSImage {
        let ratio = image.size.width / image.size.height
        let newSize = NSSize(width: height * ratio, height: height)

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(
            in: NSRect(
                x: 0, y: 0, width: newSize.width, height: newSize.height),
            from: NSRect.zero, operation: .copy, fraction: 1.0)
        newImage.unlockFocus()

        return newImage
    }
}
