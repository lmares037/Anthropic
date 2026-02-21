import SwiftUI
import SwiftData

/// On Saturdays and Sundays, recommends bodyweight exercises
/// for muscle groups that haven't reached optimal volume (12+ sets) this week.
struct WeekendRecommendationsView: View {
    let weeklyTotals: [MuscleGroup: Double]
    let allExercises: [Exercise]
    let onAddExercise: (Exercise) -> Void

    @State private var expandedMuscle: MuscleGroup?

    /// Muscle groups below optimal threshold
    private var suboptimalMuscles: [MuscleGroup] {
        MuscleGroup.allCases.filter { (weeklyTotals[$0] ?? 0) < MuscleGroup.minSetsPerWeek }
            .sorted { (weeklyTotals[$0] ?? 0) < (weeklyTotals[$1] ?? 0) }
    }

    /// Whether today is Saturday or Sunday
    private var isWeekend: Bool {
        let weekday = WorkoutViewModel.mondayCalendar.component(.weekday, from: Date())
        // In a Monday-first calendar: Mon=2, Tue=3, ... Sat=7, Sun=1
        return weekday == 1 || weekday == 7
    }

    /// Bodyweight exercises (calisthenics with no equipment or minimal equipment)
    private func bodyweightExercises(for muscle: MuscleGroup) -> [Exercise] {
        allExercises.filter { exercise in
            exercise.category == .calisthenics &&
            exercise.primaryMuscles.contains(muscle)
        }
    }

    var body: some View {
        if isWeekend && !suboptimalMuscles.isEmpty {
            VStack(spacing: AppTheme.paddingSM) {
                // Header
                HStack {
                    Image(systemName: "figure.run")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.warning)
                    Text("WEEKEND CATCH-UP")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textTertiary)
                        .tracking(1.5)
                    Spacer()
                }

                Text("These muscle groups need more volume to reach the optimal 12-set target. Try these bodyweight exercises to close the gap!")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(suboptimalMuscles) { muscle in
                    muscleRecommendationCard(for: muscle)
                }
            }
            .cardStyle()
        }
    }

    // MARK: - Per-Muscle Card

    @ViewBuilder
    private func muscleRecommendationCard(for muscle: MuscleGroup) -> some View {
        let currentSets = weeklyTotals[muscle] ?? 0
        let deficit = MuscleGroup.minSetsPerWeek - currentSets
        let exercises = bodyweightExercises(for: muscle)
        let isExpanded = expandedMuscle == muscle

        VStack(spacing: AppTheme.paddingSM) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    expandedMuscle = isExpanded ? nil : muscle
                }
            } label: {
                HStack {
                    Image(systemName: muscle.icon)
                        .font(.system(size: 14))
                        .foregroundColor(muscle.color)
                        .frame(width: 28, height: 28)
                        .background(muscle.color.opacity(0.15))
                        .cornerRadius(6)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(muscle.displayName)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)

                        HStack(spacing: 4) {
                            Text(String(format: "%.1f / 12 sets", currentSets))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.textSecondary)

                            Text("(\(String(format: "%.1f", deficit)) to go)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.warning)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }

            if isExpanded {
                if exercises.isEmpty {
                    Text("No bodyweight exercises available for this muscle group.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textTertiary)
                        .padding(.vertical, AppTheme.paddingSM)
                } else {
                    // Recommend sets to fill the gap
                    let setsNeeded = Int(ceil(deficit))
                    Text("Try \(setsNeeded) sets of any of these:")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.accentSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(exercises.prefix(4)) { exercise in
                        exerciseRow(exercise)
                    }
                }
            }
        }
        .padding(AppTheme.paddingSM)
        .background(AppTheme.surfaceElevated.opacity(0.4))
        .cornerRadius(AppTheme.radiusSM)
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: Exercise) -> some View {
        HStack(spacing: AppTheme.paddingSM) {
            Image(systemName: exercise.category.icon)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.accent)

            VStack(alignment: .leading, spacing: 1) {
                Text(exercise.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)

                if let instructions = exercise.instructions {
                    Text(instructions)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textTertiary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Quick-add button
            Button {
                onAddExercise(exercise)
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.accent)
            }
        }
        .padding(.vertical, 4)
    }
}
