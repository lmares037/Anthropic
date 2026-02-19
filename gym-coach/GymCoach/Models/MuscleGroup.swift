import Foundation
import SwiftUI

/// All trackable muscle groups for the body recomposition program.
/// Weekly target: 12-20 effective sets per group for hypertrophy.
enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case chest
    case back
    case shoulders
    case biceps
    case triceps
    case forearms
    case abdominals
    case lowerBack = "lower_back"
    case glutes
    case quadriceps
    case hamstrings
    case calves
    case adductorsAbductors = "adductors_abductors"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .forearms: return "Forearms"
        case .abdominals: return "Core"
        case .lowerBack: return "Lower Back"
        case .glutes: return "Glutes"
        case .quadriceps: return "Quads"
        case .hamstrings: return "Hamstrings"
        case .calves: return "Calves"
        case .adductorsAbductors: return "Adductors"
        }
    }

    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rowing"
        case .shoulders: return "figure.boxing"
        case .biceps: return "figure.curling"
        case .triceps: return "figure.strengthtraining.functional"
        case .forearms: return "hand.raised.fill"
        case .abdominals: return "figure.core.training"
        case .lowerBack: return "figure.flexibility"
        case .glutes: return "figure.step.training"
        case .quadriceps: return "figure.lunges"
        case .hamstrings: return "figure.run"
        case .calves: return "figure.walk"
        case .adductorsAbductors: return "figure.pilates"
        }
    }

    var color: Color {
        switch self {
        case .chest: return .red
        case .back: return .blue
        case .shoulders: return .orange
        case .biceps: return .purple
        case .triceps: return .pink
        case .forearms: return .brown
        case .abdominals: return .yellow
        case .lowerBack: return .cyan
        case .glutes: return .green
        case .quadriceps: return .indigo
        case .hamstrings: return .teal
        case .calves: return .mint
        case .adductorsAbductors: return Color(red: 0.8, green: 0.4, blue: 0.6)
        }
    }

    /// Category for grouping in UI
    var category: MuscleCategory {
        switch self {
        case .chest, .back, .shoulders:
            return .upperPush
        case .biceps, .triceps, .forearms:
            return .arms
        case .abdominals, .lowerBack:
            return .core
        case .glutes, .quadriceps, .hamstrings, .calves, .adductorsAbductors:
            return .legs
        }
    }

    static let minSetsPerWeek: Double = 12.0
    static let maxSetsPerWeek: Double = 20.0
}

enum MuscleCategory: String, CaseIterable {
    case upperPush = "Upper Body"
    case arms = "Arms"
    case core = "Core"
    case legs = "Legs"
}

/// Represents a muscle activation with its contribution percentage.
/// Primary muscles get 100%, secondary muscles get 50-75%.
struct MuscleActivation: Codable, Hashable {
    let muscle: MuscleGroup
    let activationPercent: Double // 0.5 to 1.0

    /// The effective sets contributed (sets * activationPercent)
    func effectiveSets(for sets: Int) -> Double {
        Double(sets) * activationPercent
    }
}
