import SwiftUI
import SwiftData

@main
struct GymCoachApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .task {
                    await IconExporter.exportIfNeeded()
                }
        }
        .modelContainer(for: [
            Exercise.self,
            WorkoutLog.self,
            WorkoutEntry.self
        ])
    }
}
