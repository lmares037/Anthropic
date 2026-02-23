import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutLog.date, order: .reverse) private var allLogs: [WorkoutLog]
    @State private var viewModel = WorkoutViewModel()
    @State private var showAddExercise = false
    @State private var activeLog: WorkoutLog?
    @State private var editingLog: WorkoutLog?
    @State private var showPastDatePicker = false
    @State private var pastDate = Date()
    @State private var showAddCardio = false

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
            .sheet(item: $editingLog) { log in
                EditWorkoutView(log: log)
            }
            .sheet(isPresented: $showPastDatePicker) {
                PastWorkoutDateSheet(date: $pastDate) {
                    createPastWorkout()
                }
            }
            .sheet(isPresented: $showAddCardio) {
                AddCardioSheet { cardioEntry in
                    addCardioToWorkout(cardioEntry)
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

            Button {
                pastDate = Date()
                showPastDatePicker = true
            } label: {
                HStack(spacing: AppTheme.paddingSM) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 14))
                    Text("Log a Past Workout")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(AppTheme.accentSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.accentSecondary.opacity(0.1))
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

                let totalItems = log.entries.count + log.cardioEntries.count
                Text("\(totalItems) activities")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.accent.opacity(0.15))
                    .cornerRadius(8)
            }

            // Exercise entries
            if log.entries.isEmpty && log.cardioEntries.isEmpty {
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

            // Cardio entries
            if !log.cardioEntries.isEmpty {
                ForEach(log.cardioEntries) { cardio in
                    CardioEntryRow(entry: cardio) {
                        log.cardioEntries.removeAll { $0.id == cardio.id }
                        modelContext.delete(cardio)
                    }
                }
            }

            // Add exercise / cardio buttons
            HStack(spacing: AppTheme.paddingSM) {
                Button {
                    showAddExercise = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Exercise")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
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

                Button {
                    showAddCardio = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 16))
                        Text("Cardio")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(AppTheme.accentSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.accentSecondary.opacity(0.1))
                    .cornerRadius(AppTheme.radiusMD)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                            .stroke(AppTheme.accentSecondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
                    )
                }
            }

            // Effective sets summary for this workout
            if !log.entries.isEmpty || !log.cardioEntries.isEmpty {
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
            HStack {
                Text("RECENT WORKOUTS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
                    .tracking(1.5)
                Spacer()

                Button {
                    pastDate = Date()
                    showPastDatePicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 11))
                        Text("Add Past")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(AppTheme.accentSecondary)
                }
            }

            let recentLogs = Array(allLogs.prefix(5))
            ForEach(recentLogs) { log in
                Button {
                    editingLog = log
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)

                            HStack(spacing: 6) {
                                if log.entries.count > 0 {
                                    Text("\(log.entries.count) exercises")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                if log.cardioEntries.count > 0 {
                                    Text("\(log.cardioEntries.count) cardio")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(AppTheme.accentSecondary)
                                }
                            }
                        }

                        Spacer()

                        let totalSets = log.entries.reduce(0) { $0 + $1.sets }
                        if totalSets > 0 {
                            Text("\(totalSets) sets")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(AppTheme.accent)
                        }

                        Image(systemName: "pencil.circle")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textTertiary)
                    }
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

    private func addCardioToWorkout(_ cardioEntry: CardioEntry) {
        if activeLog == nil, todaysLog == nil {
            let log = viewModel.createWorkout(context: modelContext)
            activeLog = log
            modelContext.insert(cardioEntry)
            log.cardioEntries.append(cardioEntry)
        } else if let log = activeLog ?? todaysLog {
            modelContext.insert(cardioEntry)
            log.cardioEntries.append(cardioEntry)
        }
    }

    private func createPastWorkout() {
        let log = viewModel.createWorkout(forDate: pastDate, context: modelContext)
        editingLog = log
    }
}

// MARK: - Cardio Entry Row

struct CardioEntryRow: View {
    let entry: CardioEntry
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.paddingSM) {
            HStack(alignment: .top) {
                // Activity icon
                Image(systemName: entry.activityType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.accentSecondary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.accentSecondary.opacity(0.12))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.activityType.displayName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)

                    HStack(spacing: 8) {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text(entry.formattedDuration)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }

                        if let pace = entry.formattedPace {
                            HStack(spacing: 3) {
                                Image(systemName: "speedometer")
                                    .font(.system(size: 9))
                                Text(pace)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                            }
                        }

                        if let hr = entry.avgHeartRate {
                            HStack(spacing: 3) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(AppTheme.danger)
                                Text("\(Int(hr)) bpm")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                            }
                        }
                    }
                    .foregroundColor(AppTheme.textTertiary)
                }

                Spacer()

                // Intensity badge
                VStack(spacing: 2) {
                    Text(entry.intensityLabel)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                    Text("\(Int(entry.intensity * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                .foregroundColor(intensityColor(entry.intensity))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(intensityColor(entry.intensity).opacity(0.15))
                .cornerRadius(6)
            }

            if entry.source == "healthkit" {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.red.opacity(0.7))
                    Text("From Apple Health")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                }
                .foregroundColor(AppTheme.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(AppTheme.paddingSM)
        .background(AppTheme.surfaceElevated.opacity(0.5))
        .cornerRadius(AppTheme.radiusSM)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private func intensityColor(_ intensity: Double) -> Color {
        switch intensity {
        case ..<0.45: return AppTheme.success
        case 0.45..<0.65: return AppTheme.warning
        default: return AppTheme.danger
        }
    }
}

// MARK: - Past Workout Date Picker

struct PastWorkoutDateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date

    let onCreate: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.paddingLG) {
                VStack(spacing: AppTheme.paddingSM) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 36))
                        .foregroundColor(AppTheme.accentSecondary)

                    Text("Log a Past Workout")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Select the date you worked out")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.top, AppTheme.paddingLG)

                DatePicker(
                    "Workout Date",
                    selection: $date,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(AppTheme.accent)
                .padding(.horizontal, AppTheme.paddingSM)
                .background(AppTheme.surface)
                .cornerRadius(AppTheme.radiusMD)

                Button {
                    dismiss()
                    onCreate()
                } label: {
                    Text("Create Workout")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.accent)
                        .cornerRadius(AppTheme.radiusMD)
                }

                Spacer()
            }
            .padding(.horizontal, AppTheme.paddingMD)
            .background(AppTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
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
