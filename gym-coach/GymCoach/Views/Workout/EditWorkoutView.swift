import SwiftUI
import SwiftData

/// Allows editing a workout from a previous day — add/remove exercises, adjust sets.
struct EditWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var log: WorkoutLog
    @State private var viewModel = WorkoutViewModel()
    @State private var showAddExercise = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.paddingMD) {
                    // Date header
                    dateHeader

                    // Entries
                    if log.entries.isEmpty {
                        emptyState
                    } else {
                        ForEach(log.entries) { entry in
                            EditableEntryRow(entry: entry) {
                                viewModel.removeEntry(entry, from: log, context: modelContext)
                            }
                        }
                    }

                    // Add exercise button
                    addExerciseButton

                    // Session summary
                    if !log.entries.isEmpty {
                        sessionSummary
                    }
                }
                .padding(.horizontal, AppTheme.paddingMD)
                .padding(.bottom, AppTheme.paddingXL)
            }
            .background(AppTheme.background)
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        deleteWorkout()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(AppTheme.danger)
                    }
                }
            }
            .sheet(isPresented: $showAddExercise) {
                AddExerciseSheet { exercise in
                    viewModel.addEntry(to: log, exercise: exercise, context: modelContext)
                }
            }
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        VStack(spacing: AppTheme.paddingSM) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.accent)

                Text(log.date.formatted(date: .complete, time: .omitted))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()
            }

            HStack {
                Text("\(log.entries.count) exercises")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary)

                Spacer()

                let totalSets = log.entries.reduce(0) { $0 + $1.sets }
                Text("\(totalSets) total sets")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.accent)
            }
        }
        .cardStyle()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.paddingSM) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.textTertiary)
            Text("No exercises logged")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(.vertical, AppTheme.paddingLG)
    }

    // MARK: - Add Exercise Button

    private var addExerciseButton: some View {
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
    }

    // MARK: - Session Summary

    private var sessionSummary: some View {
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
        .cardStyle()
    }

    // MARK: - Actions

    private func deleteWorkout() {
        modelContext.delete(log)
        dismiss()
    }
}

// MARK: - Editable Entry Row

struct EditableEntryRow: View {
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

            if let exercise = entry.exercise {
                MuscleTagsFlow(activations: exercise.allMuscleActivations)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Delete button
            HStack {
                Spacer()
                Button(role: .destructive) {
                    withAnimation {
                        onDelete()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                        Text("Remove")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(AppTheme.danger.opacity(0.8))
                }
            }
        }
        .padding(AppTheme.paddingSM)
        .background(AppTheme.surfaceElevated.opacity(0.5))
        .cornerRadius(AppTheme.radiusSM)
    }
}
