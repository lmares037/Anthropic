import Foundation
import HealthKit
import SwiftData

/// Imports completed workouts from Apple Health (recorded by Apple's Workout app
/// on Apple Watch or iPhone) and converts them to CardioEntry records.
///
/// Supported workout types: walking, running, boxing.
/// Each imported workout's intensity is auto-calculated using the existing
/// CardioIntensity formulas (pace for walk/run, heart rate for boxing).
///
/// **Usage:**
/// 1. Call `configure(with:)` with the SwiftData container on app launch
/// 2. Call `importNewWorkouts()` to pull new workouts from HealthKit
/// 3. Already-imported workouts are tracked by UUID in UserDefaults (deduplication)
@Observable
class HealthKitImportService {
    static let shared = HealthKitImportService()

    private let healthStore = HKHealthStore()

    var isAuthorized = false
    var isImporting = false
    var lastImportDate: Date?
    var importedCount = 0

    private var modelContainer: ModelContainer?
    private let importedIDsKey = "healthkit_imported_workout_ids"

    // MARK: - Configuration

    func configure(with container: ModelContainer) {
        self.modelContainer = container
    }

    // MARK: - Authorization

    private var readTypes: Set<HKObjectType> {
        [
            HKQuantityType.workoutType(),
            HKQuantityType(.heartRate),
            HKQuantityType(.distanceWalkingRunning),
        ]
    }

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async -> Bool {
        guard isHealthDataAvailable else { return false }
        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            await MainActor.run { self.isAuthorized = true }
            return true
        } catch {
            print("[HealthKit] Auth error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Import

    /// Import new workouts from Apple Health. Skips already-imported ones.
    /// Called on app launch and from the manual "Sync Now" button.
    @MainActor
    func importNewWorkouts() async {
        guard let container = modelContainer else { return }
        guard isHealthDataAvailable else { return }

        isImporting = true
        importedCount = 0
        defer { isImporting = false }

        let authorized = await requestAuthorization()
        guard authorized else { return }

        let importedIDs = loadImportedIDs()
        let workouts = await fetchWorkouts()

        let context = ModelContext(container)
        let calendar = Calendar.current

        // Read user age for max HR calculation
        let userAge = UserDefaults.standard.integer(forKey: "userAge")
        let maxHR = userAge > 0 ? Double(220 - userAge) : 195.0

        for workout in workouts {
            let workoutID = workout.uuid.uuidString
            guard !importedIDs.contains(workoutID) else { continue }

            guard let activityType = mapActivityType(workout.workoutActivityType) else { continue }

            let duration = workout.duration
            guard duration > 30 else { continue } // Skip very short entries

            let distance = workout.totalDistance?.doubleValue(for: .meter())
            let avgHR = await fetchAverageHeartRate(for: workout)

            // Find or create WorkoutLog for the workout's date
            let startOfDay = calendar.startOfDay(for: workout.startDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let descriptor = FetchDescriptor<WorkoutLog>(
                predicate: #Predicate { log in
                    log.date >= startOfDay && log.date < endOfDay
                }
            )

            let log: WorkoutLog
            if let existing = try? context.fetch(descriptor).first {
                log = existing
            } else {
                log = WorkoutLog(date: workout.startDate)
                context.insert(log)
            }

            // Calculate intensity using the appropriate formula
            let intensity = CardioIntensity.calculate(
                activity: activityType,
                durationSeconds: duration,
                distanceMeters: distance,
                avgHeartRate: avgHR,
                maxHR: maxHR
            )

            let entry = CardioEntry(
                activityType: activityType,
                durationSeconds: duration,
                distanceMeters: distance,
                avgHeartRate: avgHR,
                intensity: intensity,
                source: "healthkit"
            )
            // Since we passed intensity explicitly, mark it as NOT overridden
            // so it reflects the auto-calculated value
            entry.intensityOverridden = false

            context.insert(entry)
            log.cardioEntries.append(entry)

            saveImportedID(workoutID)
            importedCount += 1
        }

        try? context.save()
        lastImportDate = Date()
    }

    // MARK: - HealthKit Queries

    /// Fetch walking, running, and boxing workouts from the last 30 days.
    private func fetchWorkouts() async -> [HKWorkout] {
        let activityTypes: [HKWorkoutActivityType] = [.walking, .running, .boxing]

        let activityPredicates = activityTypes.map {
            HKQuery.predicateForWorkouts(with: $0)
        }
        let activityPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: activityPredicates)

        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let datePredicate = HKQuery.predicateForSamples(
            withStart: thirtyDaysAgo, end: Date(), options: .strictStartDate
        )

        let finalPredicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [activityPredicate, datePredicate]
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate, ascending: false
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKQuantityType.workoutType(),
                predicate: finalPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                if let error {
                    print("[HealthKit] Workout query error: \(error.localizedDescription)")
                }
                continuation.resume(returning: (results as? [HKWorkout]) ?? [])
            }
            healthStore.execute(query)
        }
    }

    /// Get the average heart rate during a workout's time window.
    private func fetchAverageHeartRate(for workout: HKWorkout) async -> Double? {
        let hrType = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate, end: workout.endDate, options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: hrType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, _ in
                let avg = statistics?.averageQuantity()?.doubleValue(
                    for: HKUnit.count().unitDivided(by: .minute())
                )
                continuation.resume(returning: avg)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Mapping

    private func mapActivityType(_ hkType: HKWorkoutActivityType) -> CardioActivityType? {
        switch hkType {
        case .walking: return .walking
        case .running: return .running
        case .boxing: return .boxing
        default: return nil
        }
    }

    // MARK: - Deduplication

    private func loadImportedIDs() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: importedIDsKey) ?? []
        return Set(array)
    }

    private func saveImportedID(_ id: String) {
        var ids = loadImportedIDs()
        ids.insert(id)
        UserDefaults.standard.set(Array(ids), forKey: importedIDsKey)
    }
}
