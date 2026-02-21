import SwiftUI
import UIKit

/// Utility to export the AppIconView as a PNG for use as the app icon.
/// Call `IconExporter.exportAppIcon()` once during development to generate the icon,
/// then add the resulting image to Assets.xcassets/AppIcon.appiconset.
enum IconExporter {
    @MainActor
    static func exportAppIcon() -> UIImage? {
        let renderer = ImageRenderer(content: AppIconView(size: 1024))
        renderer.scale = 1.0
        return renderer.uiImage
    }

    @MainActor
    static func saveAppIconToDocuments() {
        guard let image = exportAppIcon(),
              let data = image.pngData() else { return }

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent("AppIcon.png")
        try? data.write(to: fileURL)
        print("App icon saved to: \(fileURL.path)")
    }
}
