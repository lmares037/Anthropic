import Foundation

/// A workout detected on Apple Watch, serialized for transfer to iOS.
/// Shared between the Watch app and the iOS app via WatchConnectivity.
struct WatchWorkoutMessage: Codable {
    let id: String
    let activityType: String  // "walking", "running", "boxing"
    let startDate: Date
    let endDate: Date
    let durationSeconds: Double
    let distanceMeters: Double?
    let avgHeartRate: Double?
    let totalCalories: Double?
    let source: String  // "watch"

    /// Dictionary representation for WCSession message transfer
    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "activityType": activityType,
            "startDate": startDate.timeIntervalSince1970,
            "endDate": endDate.timeIntervalSince1970,
            "durationSeconds": durationSeconds,
            "source": source
        ]
        if let d = distanceMeters { dict["distanceMeters"] = d }
        if let hr = avgHeartRate { dict["avgHeartRate"] = hr }
        if let cal = totalCalories { dict["totalCalories"] = cal }
        return dict
    }

    /// Initialize from a WCSession message dictionary
    init?(from dict: [String: Any]) {
        guard let id = dict["id"] as? String,
              let activityType = dict["activityType"] as? String,
              let startInterval = dict["startDate"] as? TimeInterval,
              let endInterval = dict["endDate"] as? TimeInterval,
              let duration = dict["durationSeconds"] as? Double else {
            return nil
        }

        self.id = id
        self.activityType = activityType
        self.startDate = Date(timeIntervalSince1970: startInterval)
        self.endDate = Date(timeIntervalSince1970: endInterval)
        self.durationSeconds = duration
        self.distanceMeters = dict["distanceMeters"] as? Double
        self.avgHeartRate = dict["avgHeartRate"] as? Double
        self.totalCalories = dict["totalCalories"] as? Double
        self.source = dict["source"] as? String ?? "watch"
    }

    init(
        id: String = UUID().uuidString,
        activityType: String,
        startDate: Date,
        endDate: Date,
        durationSeconds: Double,
        distanceMeters: Double? = nil,
        avgHeartRate: Double? = nil,
        totalCalories: Double? = nil
    ) {
        self.id = id
        self.activityType = activityType
        self.startDate = startDate
        self.endDate = endDate
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.avgHeartRate = avgHeartRate
        self.totalCalories = totalCalories
        self.source = "watch"
    }
}
