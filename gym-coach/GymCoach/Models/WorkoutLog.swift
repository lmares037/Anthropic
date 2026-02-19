import Foundation
import SwiftData

/// A single workout session.
@Model
final class WorkoutLog {
    var id: UUID
    var date: Date
    @Relationship(deleteRule: .cascade) var entries: [WorkoutEntry]
    var notes: String?

    init(date: Date = .now, entries: [WorkoutEntry] = [], notes: String? = nil) {
        self.id = UUID()
        self.date = date
        self.entries = entries
        self.notes = notes
    }

    /// Total effective sets per muscle group for this workout
    var effectiveSetsByMuscle: [MuscleGroup: Double] {
        var result: [MuscleGroup: Double] = [:]
        for entry in entries {
            guard let exercise = entry.exercise else { continue }
            for activation in exercise.allMuscleActivations {
                let effective = activation.effectiveSets(for: entry.sets)
                result[activation.muscle, default: 0] += effective
            }
        }
        return result
    }
}

/// A single exercise entry within a workout (exercise + number of sets).
@Model
final class WorkoutEntry {
    var id: UUID
    @Relationship var exercise: Exercise?
    var sets: Int
    var notes: String?

    init(exercise: Exercise, sets: Int = 3, notes: String? = nil) {
        self.id = UUID()
        self.exercise = exercise
        self.sets = sets
        self.notes = notes
    }
}
