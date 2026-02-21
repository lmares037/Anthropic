import Foundation
import SwiftData
import SwiftUI

/// Central view model for workout tracking and weekly set calculations.
@Observable
class WorkoutViewModel {
    var modelContext: ModelContext?

    // MARK: - Weekly Effective Sets Calculation

    /// A calendar with Monday as the first day of the week.
    static var mondayCalendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        return cal
    }

    /// Calculates effective sets per muscle group for the current week (Monday-Sunday).
    func weeklyEffectiveSets(from logs: [WorkoutLog]) -> [MuscleGroup: Double] {
        let calendar = Self.mondayCalendar
        let now = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            return [:]
        }

        let thisWeekLogs = logs.filter { $0.date >= weekStart && $0.date <= now }
        var totals: [MuscleGroup: Double] = [:]

        for log in thisWeekLogs {
            for entry in log.entries {
                guard let exercise = entry.exercise else { continue }
                for activation in exercise.allMuscleActivations {
                    let effective = activation.effectiveSets(for: entry.sets)
                    totals[activation.muscle, default: 0] += effective
                }
            }
        }

        return totals
    }

    /// Returns progress (0.0 to 1.0+) toward the minimum weekly target for a muscle group.
    func progress(for muscle: MuscleGroup, effectiveSets: Double) -> Double {
        effectiveSets / MuscleGroup.minSetsPerWeek
    }

    /// Status color based on weekly volume.
    func statusColor(for effectiveSets: Double) -> Color {
        switch effectiveSets {
        case ..<8:
            return AppTheme.danger
        case 8..<12:
            return AppTheme.warning
        case 12...20:
            return AppTheme.success
        default:
            return AppTheme.accentSecondary // Over max — may need to pull back
        }
    }

    /// Status label for the dashboard.
    func statusLabel(for effectiveSets: Double) -> String {
        switch effectiveSets {
        case 0:
            return "Not started"
        case ..<8:
            return "Low volume"
        case 8..<12:
            return "Building"
        case 12...20:
            return "Optimal"
        default:
            return "High volume"
        }
    }

    /// Calculates effective sets per muscle group for a specific week offset (0 = this week, -1 = last week, etc.).
    func weeklyEffectiveSets(from logs: [WorkoutLog], weekOffset: Int) -> [MuscleGroup: Double] {
        let calendar = Self.mondayCalendar
        let now = Date()
        let targetDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: now) ?? now
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: targetDate) else {
            return [:]
        }

        let weekLogs = logs.filter { $0.date >= weekInterval.start && $0.date < weekInterval.end }
        var totals: [MuscleGroup: Double] = [:]

        for log in weekLogs {
            for entry in log.entries {
                guard let exercise = entry.exercise else { continue }
                for activation in exercise.allMuscleActivations {
                    let effective = activation.effectiveSets(for: entry.sets)
                    totals[activation.muscle, default: 0] += effective
                }
            }
        }

        return totals
    }

    /// Returns the Monday-Sunday week interval for a given offset from the current week.
    func weekInterval(offset: Int) -> DateInterval? {
        let calendar = Self.mondayCalendar
        let targetDate = calendar.date(byAdding: .weekOfYear, value: offset, to: Date()) ?? Date()
        return calendar.dateInterval(of: .weekOfYear, for: targetDate)
    }

    // MARK: - Workout Creation

    /// Creates a new workout log for today.
    func createWorkout(context: ModelContext) -> WorkoutLog {
        let log = WorkoutLog(date: .now)
        context.insert(log)
        return log
    }

    /// Adds an exercise entry to a workout log.
    func addEntry(to log: WorkoutLog, exercise: Exercise, sets: Int = 3, context: ModelContext) {
        let entry = WorkoutEntry(exercise: exercise, sets: sets)
        context.insert(entry)
        log.entries.append(entry)
        exercise.markUsed()
    }

    /// Removes an entry from a workout.
    func removeEntry(_ entry: WorkoutEntry, from log: WorkoutLog, context: ModelContext) {
        log.entries.removeAll { $0.id == entry.id }
        context.delete(entry)
    }
}
