import SwiftUI
import UIKit

/// Automatically generates the app icon PNG on first launch (DEBUG builds).
/// The exported icon can be dragged into Assets.xcassets/AppIcon.appiconset.
enum IconExporter {
    private static let exportedKey = "hasExportedAppIcon"

    @MainActor
    static func exportAppIcon() -> UIImage? {
        let renderer = ImageRenderer(content: AppIconView(size: 1024))
        renderer.scale = 1.0
        return renderer.uiImage
    }

    /// Auto-exports the app icon to the app's Documents directory on first launch.
    /// Prints the path to the Xcode console so the user can locate it easily.
    @MainActor
    static func exportIfNeeded() {
        #if DEBUG
        guard !UserDefaults.standard.bool(forKey: exportedKey) else { return }

        guard let image = exportAppIcon(),
              let data = image.pngData() else {
            print("[IconExporter] Failed to render app icon")
            return
        }

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent("AppIcon.png")
        do {
            try data.write(to: fileURL)
            UserDefaults.standard.set(true, forKey: exportedKey)
            print("╔════════════════════════════════════════════════════════════╗")
            print("║  APP ICON EXPORTED                                        ║")
            print("╠════════════════════════════════════════════════════════════╣")
            print("║  Your app icon has been generated at:                      ║")
            print("║  \(fileURL.path)")
            print("║                                                            ║")
            print("║  To set it as your app icon:                               ║")
            print("║  1. Open Finder and press Cmd+Shift+G                      ║")
            print("║  2. Paste the path above                                   ║")
            print("║  3. Drag AppIcon.png into Xcode's                          ║")
            print("║     Assets.xcassets > AppIcon                              ║")
            print("╚════════════════════════════════════════════════════════════╝")
        } catch {
            print("[IconExporter] Failed to save: \(error)")
        }
        #endif
    }

    /// Force re-export (e.g. from a settings button). Returns the file URL.
    @MainActor
    static func forceExport() -> URL? {
        guard let image = exportAppIcon(),
              let data = image.pngData() else { return nil }

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent("AppIcon.png")
        try? data.write(to: fileURL)
        UserDefaults.standard.set(true, forKey: exportedKey)
        return fileURL
    }
}
