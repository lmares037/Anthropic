import SwiftUI

@main
struct GymCoachWatchApp: App {
    @StateObject private var workoutManager = WatchWorkoutManager()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(workoutManager)
        }
    }
}
