import SwiftUI
import SwiftData

@main
struct GymCoachApp: App {
    @State private var healthKitService = HealthKitImportService.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .environment(healthKitService)
                .task {
                    await IconExporter.exportIfNeeded()
                    await healthKitService.importNewWorkouts()
                }
        }
        .modelContainer(for: [
            Exercise.self,
            WorkoutLog.self,
            WorkoutEntry.self,
            CardioEntry.self
        ]) { result in
            if case .success(let container) = result {
                HealthKitImportService.shared.configure(with: container)
            }
        }
    }
}
