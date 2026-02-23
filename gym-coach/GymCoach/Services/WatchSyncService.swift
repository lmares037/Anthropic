import Foundation
import WatchConnectivity
import SwiftData
import SwiftUI

/// iOS-side service that receives workout data from the Apple Watch companion app.
/// Incoming workouts are converted to CardioEntry objects and added to the appropriate WorkoutLog.
class WatchSyncService: NSObject, ObservableObject {
    static let shared = WatchSyncService()

    @Published var lastSyncDate: Date?
    @Published var pendingWorkouts: [WatchWorkoutMessage] = []

    private var modelContainer: ModelContainer?

    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    /// Set the SwiftData model container so we can create entries from received workouts
    func configure(with container: ModelContainer) {
        self.modelContainer = container
    }

    /// Whether the Watch is paired and reachable
    var isWatchConnected: Bool {
        guard WCSession.isSupported() else { return false }
        return WCSession.default.isPaired && WCSession.default.isWatchAppInstalled
    }

    /// Process a received workout from the Watch and save it to SwiftData
    @MainActor
    private func processWorkout(_ message: WatchWorkoutMessage) {
        guard let container = modelContainer else {
            pendingWorkouts.append(message)
            return
        }

        let context = ModelContext(container)

        // Find or create a WorkoutLog for the workout's date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: message.startDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        let descriptor = FetchDescriptor<WorkoutLog>(
            predicate: #Predicate { log in
                log.date >= startOfDay && log.date < endOfDay
            }
        )

        let log: WorkoutLog
        if let existing = try? context.fetch(descriptor).first {
            log = existing
        } else {
            log = WorkoutLog(date: message.startDate)
            context.insert(log)
        }

        // Convert activity type
        let activityType: CardioActivityType
        switch message.activityType {
        case "running": activityType = .running
        case "boxing": activityType = .boxing
        default: activityType = .walking
        }

        // Create the cardio entry
        let cardioEntry = CardioEntry(
            activityType: activityType,
            durationSeconds: message.durationSeconds,
            distanceMeters: message.distanceMeters,
            avgHeartRate: message.avgHeartRate,
            source: "watch"
        )

        context.insert(cardioEntry)
        log.cardioEntries.append(cardioEntry)

        try? context.save()

        lastSyncDate = Date()
    }
}

// MARK: - WCSessionDelegate

extension WatchSyncService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("[WatchSync] Activation error: \(error.localizedDescription)")
        } else {
            print("[WatchSync] Session activated: \(activationState.rawValue)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    /// Receive live messages from the Watch (when app is in foreground)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let workout = WatchWorkoutMessage(from: message) else { return }
        Task { @MainActor in
            processWorkout(workout)
        }
    }

    /// Receive messages with reply handler
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let workout = WatchWorkoutMessage(from: message) else {
            replyHandler(["status": "error", "reason": "invalid_message"])
            return
        }
        Task { @MainActor in
            processWorkout(workout)
            replyHandler(["status": "ok"])
        }
    }

    /// Receive background transfers (queued when iOS app was not running)
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let workout = WatchWorkoutMessage(from: userInfo) else { return }
        Task { @MainActor in
            processWorkout(workout)
        }
    }
}
