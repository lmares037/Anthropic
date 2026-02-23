import Foundation
import HealthKit
import WatchConnectivity

/// Manages HealthKit workout sessions on Apple Watch and syncs completed workouts to iPhone.
///
/// Supported workout types:
/// - Walking (HKWorkoutActivityType.walking)
/// - Running (HKWorkoutActivityType.running)
/// - Boxing (HKWorkoutActivityType.boxing)
///
/// When a workout ends, it:
/// 1. Reads duration, distance, and heart rate from HealthKit
/// 2. Packages data as a WatchWorkoutMessage
/// 3. Sends to iPhone via WatchConnectivity (live message or background transfer)
class WatchWorkoutManager: NSObject, ObservableObject {
    let healthStore = HKHealthStore()

    @Published var isWorkoutActive = false
    @Published var currentActivityType: String = "running"
    @Published var elapsedSeconds: Double = 0
    @Published var heartRate: Double = 0
    @Published var distance: Double = 0 // meters
    @Published var calories: Double = 0
    @Published var isSynced = false

    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var startDate: Date?
    private var timer: Timer?

    override init() {
        super.init()
        activateWCSession()
    }

    // MARK: - HealthKit Authorization

    /// Request permission to read/write workout data
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        let typesToShare: Set<HKSampleType> = [
            HKQuantityType.workoutType()
        ]

        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.workoutType(),
            HKQuantityType(.heartRate),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.activeEnergyBurned),
        ]

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            return true
        } catch {
            print("[Watch] HealthKit auth error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Workout Session

    /// Start a workout session for the given activity
    func startWorkout(activityType: String) async {
        guard !isWorkoutActive else { return }
        let authorized = await requestAuthorization()
        guard authorized else { return }

        let hkActivityType: HKWorkoutActivityType
        switch activityType {
        case "running": hkActivityType = .running
        case "boxing": hkActivityType = .boxing
        default: hkActivityType = .walking
        }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = hkActivityType
        configuration.locationType = hkActivityType == .boxing ? .indoor : .outdoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()

            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

            session.delegate = self
            builder.delegate = self

            self.session = session
            self.builder = builder
            self.currentActivityType = activityType
            self.startDate = Date()

            session.startActivity(with: Date())
            try await builder.beginCollection(at: Date())

            await MainActor.run {
                self.isWorkoutActive = true
                self.elapsedSeconds = 0
                self.heartRate = 0
                self.distance = 0
                self.calories = 0
                self.isSynced = false
                self.startTimer()
            }
        } catch {
            print("[Watch] Failed to start workout: \(error.localizedDescription)")
        }
    }

    /// End the current workout and sync to iPhone
    func endWorkout() async {
        guard isWorkoutActive, let session, let builder else { return }

        session.end()

        do {
            try await builder.endCollection(at: Date())
            try await builder.finishWorkout()
        } catch {
            print("[Watch] Failed to finish workout: \(error.localizedDescription)")
        }

        let endDate = Date()
        let duration = endDate.timeIntervalSince(startDate ?? endDate)

        // Build the message
        let message = WatchWorkoutMessage(
            activityType: currentActivityType,
            startDate: startDate ?? endDate,
            endDate: endDate,
            durationSeconds: duration,
            distanceMeters: distance > 0 ? distance : nil,
            avgHeartRate: heartRate > 0 ? heartRate : nil,
            totalCalories: calories > 0 ? calories : nil
        )

        // Send to iPhone
        sendToPhone(message)

        await MainActor.run {
            self.isWorkoutActive = false
            self.stopTimer()
        }

        self.session = nil
        self.builder = nil
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, let start = self.startDate else { return }
            Task { @MainActor in
                self.elapsedSeconds = Date().timeIntervalSince(start)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - WatchConnectivity

    private func activateWCSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Send completed workout data to the paired iPhone
    private func sendToPhone(_ message: WatchWorkoutMessage) {
        guard WCSession.default.activationState == .activated else {
            // Queue as user info transfer (delivered in background)
            WCSession.default.transferUserInfo(message.asDictionary)
            return
        }

        if WCSession.default.isReachable {
            // Send live message with reply handler
            WCSession.default.sendMessage(message.asDictionary, replyHandler: { [weak self] reply in
                if reply["status"] as? String == "ok" {
                    Task { @MainActor in
                        self?.isSynced = true
                    }
                }
            }, errorHandler: { [weak self] error in
                print("[Watch] Send message error: \(error.localizedDescription)")
                // Fall back to background transfer
                WCSession.default.transferUserInfo(message.asDictionary)
                Task { @MainActor in
                    self?.isSynced = true // Will arrive eventually
                }
            })
        } else {
            // Phone not reachable — queue for later
            WCSession.default.transferUserInfo(message.asDictionary)
            Task { @MainActor in
                self.isSynced = true // Queued
            }
        }
    }

    // MARK: - Formatting

    var formattedElapsedTime: String {
        let total = Int(elapsedSeconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WatchWorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        // State changes handled in start/end methods
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("[Watch] Workout session error: \(error.localizedDescription)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WatchWorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }

            let statistics = workoutBuilder.statistics(for: quantityType)

            Task { @MainActor in
                switch quantityType {
                case HKQuantityType(.heartRate):
                    let bpm = statistics?.mostRecentQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0
                    self.heartRate = bpm

                case HKQuantityType(.distanceWalkingRunning):
                    let meters = statistics?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                    self.distance = meters

                case HKQuantityType(.activeEnergyBurned):
                    let kcal = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                    self.calories = kcal

                default:
                    break
                }
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchWorkoutManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("[Watch] WC activation error: \(error.localizedDescription)")
        }
    }
}
