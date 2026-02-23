import Foundation
import SwiftData

/// A time-based cardio/activity entry within a workout.
/// Used for activities like walking, running, and boxing that are measured
/// by duration rather than sets.
@Model
final class CardioEntry {
    var id: UUID

    /// The type of cardio activity
    var activityTypeRaw: String

    /// Duration in seconds
    var durationSeconds: Double

    /// Distance in meters (for walking/running)
    var distanceMeters: Double?

    /// Average heart rate in BPM (from Apple Watch if available)
    var avgHeartRate: Double?

    /// Calculated intensity (0.0 to 1.0), can be overridden by user
    var intensity: Double

    /// Whether the user manually adjusted the intensity
    var intensityOverridden: Bool

    /// Optional notes
    var notes: String?

    /// Source of the data: "manual", "watch", "healthkit"
    var source: String

    init(
        activityType: CardioActivityType,
        durationSeconds: Double,
        distanceMeters: Double? = nil,
        avgHeartRate: Double? = nil,
        intensity: Double? = nil,
        source: String = "manual"
    ) {
        self.id = UUID()
        self.activityTypeRaw = activityType.rawValue
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.avgHeartRate = avgHeartRate
        self.intensityOverridden = false
        self.source = source

        // Auto-calculate intensity if not provided
        if let intensity {
            self.intensity = intensity
            self.intensityOverridden = true
        } else {
            self.intensity = CardioIntensity.calculate(
                activity: activityType,
                durationSeconds: durationSeconds,
                distanceMeters: distanceMeters,
                avgHeartRate: avgHeartRate
            )
        }
    }

    var activityType: CardioActivityType {
        CardioActivityType(rawValue: activityTypeRaw) ?? .walking
    }

    /// Formatted duration string (e.g. "32:15" or "1:05:30")
    var formattedDuration: String {
        let total = Int(durationSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Pace in min/km for walking/running
    var paceMinPerKm: Double? {
        guard let dist = distanceMeters, dist > 0 else { return nil }
        let km = dist / 1000.0
        let minutes = durationSeconds / 60.0
        return minutes / km
    }

    /// Formatted pace (e.g. "5:30 /km")
    var formattedPace: String? {
        guard let pace = paceMinPerKm else { return nil }
        let mins = Int(pace)
        let secs = Int((pace - Double(mins)) * 60)
        return String(format: "%d:%02d /km", mins, secs)
    }

    /// Recalculate intensity from current metrics (does not override user-set intensity)
    func recalculateIntensity() {
        guard !intensityOverridden else { return }
        intensity = CardioIntensity.calculate(
            activity: activityType,
            durationSeconds: durationSeconds,
            distanceMeters: distanceMeters,
            avgHeartRate: avgHeartRate
        )
    }

    /// The intensity label for display
    var intensityLabel: String {
        CardioIntensity.label(for: intensity)
    }

    /// Effective sets equivalent for this cardio session.
    /// Converts time-based workouts into an equivalent "effective sets" value
    /// so they contribute to the weekly volume dashboard.
    var effectiveSetsByMuscle: [MuscleGroup: Double] {
        CardioIntensity.effectiveSets(
            activity: activityType,
            durationSeconds: durationSeconds,
            intensity: intensity
        )
    }
}

// MARK: - Activity Types

enum CardioActivityType: String, Codable, CaseIterable, Identifiable {
    case walking
    case running
    case boxing

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .walking: return "Walking"
        case .running: return "Running"
        case .boxing: return "Boxing"
        }
    }

    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .boxing: return "figure.boxing"
        }
    }

    /// Muscles activated by this cardio activity
    var muscleActivations: [(muscle: MuscleGroup, weight: Double)] {
        switch self {
        case .walking:
            return [
                (.quadriceps, 0.6),
                (.hamstrings, 0.5),
                (.calves, 0.7),
                (.glutes, 0.5),
            ]
        case .running:
            return [
                (.quadriceps, 0.8),
                (.hamstrings, 0.7),
                (.calves, 0.9),
                (.glutes, 0.7),
                (.abdominals, 0.3),
            ]
        case .boxing:
            return [
                (.shoulders, 0.8),
                (.chest, 0.5),
                (.back, 0.5),
                (.biceps, 0.6),
                (.triceps, 0.6),
                (.abdominals, 0.7),
                (.calves, 0.4),
            ]
        }
    }
}

// MARK: - Intensity Calculation

/// Formulas for auto-calculating workout intensity from measurable metrics.
///
/// **Walking & Running — Pace-based:**
/// Intensity is derived from pace (min/km). Faster pace = higher intensity.
/// The formula maps pace to a 0-1 scale using known physiological zones:
///
/// | Activity | Recovery  | Easy      | Moderate  | Hard      | Max       |
/// |----------|-----------|-----------|-----------|-----------|-----------|
/// | Walking  | >15 min/km| 12 min/km | 9 min/km  | 7 min/km  | <6 min/km |
/// | Running  | >8 min/km | 7 min/km  | 5:30/km   | 4:30/km   | <3:30/km  |
///
/// **Boxing — Heart Rate-based:**
/// Uses % of estimated max heart rate (220 - age, defaulting to age 25 = 195 bpm).
/// Falls back to duration-based estimate if no heart rate data.
///
/// | %MaxHR  | <50%   | 50-60% | 60-70% | 70-85% | 85%+   |
/// |---------|--------|--------|--------|--------|--------|
/// | Zone    | Warmup | Easy   | Moderate| Hard  | Max    |
/// | Intensity| 0.2   | 0.4    | 0.6    | 0.8   | 1.0    |
enum CardioIntensity {

    /// Estimated max heart rate (using 220 - age, default age 25)
    static let estimatedMaxHR: Double = 195.0

    /// Calculate intensity for an activity given available metrics.
    static func calculate(
        activity: CardioActivityType,
        durationSeconds: Double,
        distanceMeters: Double?,
        avgHeartRate: Double?
    ) -> Double {
        switch activity {
        case .walking:
            return walkingIntensity(durationSeconds: durationSeconds, distanceMeters: distanceMeters)
        case .running:
            return runningIntensity(durationSeconds: durationSeconds, distanceMeters: distanceMeters)
        case .boxing:
            return boxingIntensity(durationSeconds: durationSeconds, avgHeartRate: avgHeartRate)
        }
    }

    // MARK: - Walking Intensity (pace-based)

    /// Walking pace zones (min/km):
    /// - Slow stroll: >15 min/km → 0.15
    /// - Easy walk: ~12 min/km → 0.3
    /// - Brisk walk: ~9 min/km → 0.5
    /// - Power walk: ~7 min/km → 0.7
    /// - Race walk: <6 min/km → 0.9
    static func walkingIntensity(durationSeconds: Double, distanceMeters: Double?) -> Double {
        guard let dist = distanceMeters, dist > 0 else {
            // No distance data — estimate from duration alone
            // Assume moderate intensity for walks 20-60 min
            let minutes = durationSeconds / 60.0
            return clamp(minutes / 60.0 * 0.5, min: 0.15, max: 0.6)
        }

        let paceMinPerKm = (durationSeconds / 60.0) / (dist / 1000.0)

        // Map pace to intensity: faster pace = higher intensity
        // 15 min/km = 0.15, 6 min/km = 0.9
        let intensity = mapRange(paceMinPerKm, fromLow: 15.0, fromHigh: 6.0, toLow: 0.15, toHigh: 0.9)
        return clamp(intensity, min: 0.1, max: 0.95)
    }

    // MARK: - Running Intensity (pace-based)

    /// Running pace zones (min/km):
    /// - Recovery jog: >8 min/km → 0.2
    /// - Easy run: ~7 min/km → 0.4
    /// - Tempo run: ~5:30/km → 0.6
    /// - Threshold: ~4:30/km → 0.8
    /// - Sprint/VO2max: <3:30/km → 1.0
    static func runningIntensity(durationSeconds: Double, distanceMeters: Double?) -> Double {
        guard let dist = distanceMeters, dist > 0 else {
            // No distance — estimate from duration
            // Short runs tend to be harder; long runs more moderate
            let minutes = durationSeconds / 60.0
            if minutes < 20 { return 0.7 }       // Likely interval/speed work
            if minutes < 45 { return 0.55 }       // Moderate run
            return 0.45                            // Long slow distance
        }

        let paceMinPerKm = (durationSeconds / 60.0) / (dist / 1000.0)

        // Map pace to intensity: 8 min/km = 0.2, 3.5 min/km = 1.0
        let intensity = mapRange(paceMinPerKm, fromLow: 8.0, fromHigh: 3.5, toLow: 0.2, toHigh: 1.0)
        return clamp(intensity, min: 0.15, max: 1.0)
    }

    // MARK: - Boxing Intensity (heart rate-based)

    /// Boxing uses heart rate when available:
    /// - %maxHR < 50% → 0.2 (warm-up)
    /// - %maxHR 50-60% → 0.4 (technique work)
    /// - %maxHR 60-70% → 0.6 (moderate bag work)
    /// - %maxHR 70-85% → 0.8 (hard sparring/pads)
    /// - %maxHR > 85% → 0.95 (all-out rounds)
    ///
    /// Without heart rate, falls back to duration-based estimate.
    static func boxingIntensity(durationSeconds: Double, avgHeartRate: Double?) -> Double {
        if let hr = avgHeartRate, hr > 0 {
            let percentMax = hr / estimatedMaxHR
            let intensity = mapRange(percentMax, fromLow: 0.5, fromHigh: 0.9, toLow: 0.3, toHigh: 1.0)
            return clamp(intensity, min: 0.2, max: 1.0)
        }

        // No heart rate — estimate from duration
        // Short sessions (< 20 min) are typically high intensity drills
        // Longer sessions (> 45 min) include more rest and technique
        let minutes = durationSeconds / 60.0
        if minutes < 20 { return 0.75 }
        if minutes < 45 { return 0.65 }
        return 0.55
    }

    // MARK: - Effective Sets Conversion

    /// Converts a cardio session into equivalent effective sets for muscle tracking.
    ///
    /// Formula: For each muscle activated by the activity:
    ///   effectiveSets = (durationMinutes / 15) * intensity * muscleWeight
    ///
    /// This means a 30-minute moderate (0.5) run contributes:
    ///   quads: (30/15) * 0.5 * 0.8 = 0.8 effective sets
    ///   hamstrings: (30/15) * 0.5 * 0.7 = 0.7 effective sets
    ///   etc.
    ///
    /// The 15-minute divisor is chosen so cardio doesn't overwhelm
    /// weight training volume in the weekly tracker.
    static func effectiveSets(
        activity: CardioActivityType,
        durationSeconds: Double,
        intensity: Double
    ) -> [MuscleGroup: Double] {
        let durationFactor = (durationSeconds / 60.0) / 15.0 // 15 min = 1 unit
        var result: [MuscleGroup: Double] = [:]

        for activation in activity.muscleActivations {
            let sets = durationFactor * intensity * activation.weight
            result[activation.muscle, default: 0] += sets
        }

        return result
    }

    // MARK: - Display

    static func label(for intensity: Double) -> String {
        switch intensity {
        case ..<0.25: return "Recovery"
        case 0.25..<0.45: return "Easy"
        case 0.45..<0.65: return "Moderate"
        case 0.65..<0.85: return "Hard"
        default: return "Max"
        }
    }

    static func color(for intensity: Double) -> String {
        switch intensity {
        case ..<0.25: return "success"
        case 0.25..<0.45: return "success"
        case 0.45..<0.65: return "warning"
        case 0.65..<0.85: return "danger"
        default: return "danger"
        }
    }

    // MARK: - Helpers

    private static func mapRange(_ value: Double, fromLow: Double, fromHigh: Double, toLow: Double, toHigh: Double) -> Double {
        let proportion = (value - fromLow) / (fromHigh - fromLow)
        return toLow + proportion * (toHigh - toLow)
    }

    private static func clamp(_ value: Double, min minVal: Double, max maxVal: Double) -> Double {
        Swift.min(maxVal, Swift.max(minVal, value))
    }
}
