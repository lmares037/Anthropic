import SwiftUI
import SwiftData

@main
struct GymCoachApp: App {
    @StateObject private var watchSync = WatchSyncService.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .environmentObject(watchSync)
                .task {
                    await IconExporter.exportIfNeeded()
                }
        }
        .modelContainer(for: [
            Exercise.self,
            WorkoutLog.self,
            WorkoutEntry.self,
            CardioEntry.self
        ]) { result in
            if case .success(let container) = result {
                WatchSyncService.shared.configure(with: container)
            }
        }
    }
}
