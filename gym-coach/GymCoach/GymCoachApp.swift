import SwiftUI
import SwiftData

@main
struct GymCoachApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [
            Exercise.self,
            WorkoutLog.self,
            WorkoutEntry.self
        ])
    }
}
