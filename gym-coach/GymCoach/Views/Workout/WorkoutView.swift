import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutLog.date, order: .reverse) private var allLogs: [WorkoutLog]
    @State private var viewModel = WorkoutViewModel()
    @State private var showAddExercise = false
    @State private var activeLog: WorkoutLog?

    /// Today's workout log, if one exists
    private var todaysLog: WorkoutLog? {
        allLogs.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.paddingLG) {
                    if let log = activeLog ?? todaysLog {
                        activeWorkoutSection(log: log)
                    } else {
                        startWorkoutSection
                    }

                    if !allLogs.isEmpty {
                        recentWorkoutsSection
                    }
                }
                .padding(.horizontal, AppTheme.paddingMD)
                .padding(.bottom, 100)
            }
            .background(AppTheme.background)
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showAddExercise) {
                AddExerciseSheet { exercise in
                    addExerciseToWorkout(exercise)
                }
            }
        }
    }

    // MARK: - Start Workout

    private var startWorkoutSection: some View {
        VStack(spacing: AppTheme.paddingMD) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.accent.opacity(0.6))

            Text("Ready to train?")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)

            Text("Start a workout to begin tracking sets")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)

            Button {
                let log = viewModel.createWorkout(context: modelContext)
                activeLog = log
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            } label: {
                Text("Start Workout")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.accent)
                    .cornerRadius(AppTheme.radiusMD)
            }
        }
        .padding(.top, AppTheme.paddingXL)
        .cardStyle()
    }

    // MARK: - Active Workout

    private func activeWorkoutSection(log: WorkoutLog) -> some View {
        VStack(spacing: AppTheme.paddingMD) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Workout")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)

                    Text(log.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                Text("\(log.entries.count) exercises")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.accent.opacity(0.15))
                    .cornerRadius(8)
            }

            // Exercise entries
            if log.entries.isEmpty {
                VStack(spacing: AppTheme.paddingSM) {
                    Text("No exercises yet")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textTertiary)
                    Text("Tap + to add your first exercise")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textTertiary)
                }
                .padding(.vertical, AppTheme.paddingLG)
            } else {
                ForEach(log.entries) { entry in
                    WorkoutEntryRow(entry: entry) {
                        viewModel.removeEntry(entry, from: log, context: modelContext)
                    }
                }
            }

            // Add exercise button
            Button {
                showAddExercise = true
            } label: {
                HStack(spacing: AppTheme.paddingSM) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Add Exercise")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundColor(AppTheme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.accent.opacity(0.1))
                .cornerRadius(AppTheme.radiusMD)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                        .stroke(AppTheme.accent.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
                )
            }

            // Effective sets summary for this workout
            if !log.entries.isEmpty {
                workoutSummary(log: log)
            }
        }
        .cardStyle()
    }

    // MARK: - Workout Summary

    private func workoutSummary(log: WorkoutLog) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            Text("SESSION VOLUME")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textTertiary)
                .tracking(1.5)

            let setsByMuscle = log.effectiveSetsByMuscle.sorted { $0.value > $1.value }
            ForEach(setsByMuscle, id: \.key) { muscle, sets in
                HStack {
                    Circle()
                        .fill(muscle.color)
                        .frame(width: 8, height: 8)

                    Text(muscle.displayName)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary)

                    Spacer()

                    Text(String(format: "%.1f sets", sets))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
        .padding(.top, AppTheme.paddingSM)
    }

    // MARK: - Recent Workouts

    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            Text("RECENT WORKOUTS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textTertiary)
                .tracking(1.5)

            let recentLogs = Array(allLogs.prefix(5))
            ForEach(recentLogs) { log in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(log.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)

                        Text("\(log.entries.count) exercises")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Spacer()

                    let totalSets = log.entries.reduce(0) { $0 + $1.sets }
                    Text("\(totalSets) sets")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.accent)
                }
                .padding(.vertical, AppTheme.paddingSM)

                if log.id != recentLogs.last?.id {
                    Divider()
                        .background(AppTheme.surfaceBorder)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Actions

    private func addExerciseToWorkout(_ exercise: Exercise) {
        if activeLog == nil, todaysLog == nil {
            let log = viewModel.createWorkout(context: modelContext)
            activeLog = log
            viewModel.addEntry(to: log, exercise: exercise, context: modelContext)
        } else if let log = activeLog ?? todaysLog {
            viewModel.addEntry(to: log, exercise: exercise, context: modelContext)
        }
    }
}

// MARK: - Workout Entry Row

struct WorkoutEntryRow: View {
    @Bindable var entry: WorkoutEntry
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.paddingSM) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.exercise?.name ?? "Unknown")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)

                    if let exercise = entry.exercise {
                        HStack(spacing: 4) {
                            Image(systemName: exercise.category.icon)
                                .font(.system(size: 10))
                            Text(exercise.equipment.displayName)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(AppTheme.textTertiary)
                    }
                }

                Spacer()

                SetCounter(sets: $entry.sets)
            }

            // Muscle tags
            if let exercise = entry.exercise {
                MuscleTagsFlow(activations: exercise.allMuscleActivations)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(AppTheme.paddingSM)
        .background(AppTheme.surfaceElevated.opacity(0.5))
        .cornerRadius(AppTheme.radiusSM)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}
