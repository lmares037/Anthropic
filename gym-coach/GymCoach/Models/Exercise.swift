import Foundation
import SwiftData

/// An exercise with its muscle activation profile.
@Model
final class Exercise {
    var id: UUID
    var name: String
    var category: ExerciseCategory
    var equipment: EquipmentType

    /// Primary muscles (100% activation)
    var primaryMusclesRaw: [String]
    /// Secondary muscles stored as "muscle:percent" (e.g., "triceps:0.5")
    var secondaryMusclesRaw: [String]

    /// Whether this was added by the user (vs. pre-loaded)
    var isCustom: Bool
    /// Last time this exercise was used in a workout
    var lastUsedDate: Date?
    /// Number of times this exercise has been logged
    var useCount: Int

    var instructions: String?

    init(
        name: String,
        category: ExerciseCategory,
        equipment: EquipmentType,
        primaryMuscles: [MuscleGroup],
        secondaryMuscles: [MuscleActivation],
        isCustom: Bool = false,
        instructions: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.equipment = equipment
        self.primaryMusclesRaw = primaryMuscles.map { $0.rawValue }
        self.secondaryMusclesRaw = secondaryMuscles.map { "\($0.muscle.rawValue):\($0.activationPercent)" }
        self.isCustom = isCustom
        self.lastUsedDate = nil
        self.useCount = 0
        self.instructions = instructions
    }

    // MARK: - Computed Properties

    var primaryMuscles: [MuscleGroup] {
        primaryMusclesRaw.compactMap { MuscleGroup(rawValue: $0) }
    }

    var secondaryMuscles: [MuscleActivation] {
        secondaryMusclesRaw.compactMap { raw in
            let parts = raw.split(separator: ":")
            guard parts.count == 2,
                  let muscle = MuscleGroup(rawValue: String(parts[0])),
                  let percent = Double(parts[1]) else { return nil }
            return MuscleActivation(muscle: muscle, activationPercent: percent)
        }
    }

    /// All muscle activations (primary at 100% + secondary at their percentages)
    var allMuscleActivations: [MuscleActivation] {
        let primary = primaryMuscles.map { MuscleActivation(muscle: $0, activationPercent: 1.0) }
        return primary + secondaryMuscles
    }

    /// Mark this exercise as used now
    func markUsed() {
        lastUsedDate = Date()
        useCount += 1
    }
}

// MARK: - Enums

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case calisthenics
    case machine
    case freeWeight = "free_weight"
    case cable
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .calisthenics: return "Calisthenics"
        case .machine: return "Machine"
        case .freeWeight: return "Free Weight"
        case .cable: return "Cable"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .calisthenics: return "figure.strengthtraining.functional"
        case .machine: return "gearshape.fill"
        case .freeWeight: return "dumbbell.fill"
        case .cable: return "cable.connector"
        case .custom: return "plus.circle.fill"
        }
    }
}

enum EquipmentType: String, Codable, CaseIterable {
    case none
    case barbell
    case dumbbell
    case kettlebell
    case machine
    case cable
    case resistanceBand = "resistance_band"
    case pullUpBar = "pull_up_bar"
    case dipStation = "dip_station"
    case bench
    case other

    var displayName: String {
        switch self {
        case .none: return "Bodyweight"
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .kettlebell: return "Kettlebell"
        case .machine: return "Machine"
        case .cable: return "Cable"
        case .resistanceBand: return "Band"
        case .pullUpBar: return "Pull-Up Bar"
        case .dipStation: return "Dip Station"
        case .bench: return "Bench"
        case .other: return "Other"
        }
    }
}
