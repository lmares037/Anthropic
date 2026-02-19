import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var selectedMuscle: MuscleGroup?
    @State private var selectedExercise: Exercise?

    private var filteredExercises: [Exercise] {
        allExercises.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil ||
                exercise.category == selectedCategory
            let matchesMuscle = selectedMuscle == nil ||
                exercise.primaryMuscles.contains(selectedMuscle!) ||
                exercise.secondaryMuscles.contains { $0.muscle == selectedMuscle! }
            return matchesSearch && matchesCategory && matchesMuscle
        }
    }

    /// Group exercises by category for display.
    private var groupedExercises: [(ExerciseCategory, [Exercise])] {
        let grouped = Dictionary(grouping: filteredExercises) { $0.category }
        return ExerciseCategory.allCases.compactMap { cat in
            guard let exercises = grouped[cat], !exercises.isEmpty else { return nil }
            return (cat, exercises.sorted { $0.name < $1.name })
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.paddingMD) {
                    // Search
                    searchBar

                    // Filters
                    categoryPills
                    musclePills

                    // Stats
                    exerciseCount

                    // Exercise list
                    ForEach(groupedExercises, id: \.0) { category, exercises in
                        exerciseSection(category: category, exercises: exercises)
                    }
                }
                .padding(.horizontal, AppTheme.paddingMD)
                .padding(.bottom, AppTheme.paddingXL)
            }
            .background(AppTheme.background)
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailSheet(exercise: exercise)
            }
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: AppTheme.paddingSM) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.textTertiary)

            TextField("Search exercises...", text: $searchText)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
        }
        .padding(AppTheme.paddingSM + 4)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.radiusMD)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
        )
    }

    // MARK: - Filters

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                FilterPill(title: "All", isSelected: selectedCategory == nil, color: AppTheme.accent) {
                    selectedCategory = nil
                }
                ForEach(ExerciseCategory.allCases) { cat in
                    FilterPill(title: cat.displayName, icon: cat.icon, isSelected: selectedCategory == cat, color: AppTheme.accent) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
        }
    }

    private var musclePills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(MuscleGroup.allCases) { muscle in
                    FilterPill(title: muscle.displayName, isSelected: selectedMuscle == muscle, color: muscle.color) {
                        selectedMuscle = selectedMuscle == muscle ? nil : muscle
                    }
                }
            }
        }
    }

    private var exerciseCount: some View {
        HStack {
            Text("\(filteredExercises.count) exercises")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.textTertiary)
            Spacer()
        }
    }

    // MARK: - Exercise Sections

    private func exerciseSection(category: ExerciseCategory, exercises: [Exercise]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            HStack(spacing: AppTheme.paddingSM) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.accent)
                Text(category.displayName.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
                    .tracking(1.5)
                Spacer()
                Text("\(exercises.count)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
            }

            ForEach(exercises) { exercise in
                Button {
                    selectedExercise = exercise
                } label: {
                    LibraryExerciseRow(exercise: exercise)
                }
            }
        }
    }
}

// MARK: - Library Exercise Row

struct LibraryExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: AppTheme.paddingSM + 4) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(exercise.name)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)

                    if exercise.isCustom {
                        Text("CUSTOM")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.accentSecondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(AppTheme.accentSecondary.opacity(0.15))
                            .cornerRadius(3)
                    }
                }

                HStack(spacing: 4) {
                    Text(exercise.equipment.displayName)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textTertiary)

                    Text("•")
                        .foregroundColor(AppTheme.textTertiary)

                    ForEach(exercise.primaryMuscles.prefix(3), id: \.self) { muscle in
                        HStack(spacing: 2) {
                            Circle().fill(muscle.color).frame(width: 5, height: 5)
                            Text(muscle.displayName)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(AppTheme.paddingSM + 2)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.radiusSM)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusSM)
                .stroke(AppTheme.surfaceBorder, lineWidth: 0.5)
        )
    }
}

// MARK: - Exercise Detail Sheet

struct ExerciseDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.paddingLG) {
                    // Header
                    VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
                        HStack {
                            Image(systemName: exercise.category.icon)
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.accent)
                                .frame(width: 40, height: 40)
                                .background(AppTheme.accent.opacity(0.12))
                                .cornerRadius(10)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.category.displayName)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(AppTheme.textTertiary)
                                Text(exercise.equipment.displayName)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        }
                    }

                    // Primary Muscles
                    VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
                        Text("PRIMARY MUSCLES (100%)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textTertiary)
                            .tracking(1)

                        ForEach(exercise.primaryMuscles, id: \.self) { muscle in
                            HStack {
                                Circle().fill(muscle.color).frame(width: 10, height: 10)
                                Text(muscle.displayName)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                Text("100%")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.success)
                            }
                            .padding(AppTheme.paddingSM)
                            .background(muscle.color.opacity(0.08))
                            .cornerRadius(AppTheme.radiusSM)
                        }
                    }

                    // Secondary Muscles
                    if !exercise.secondaryMuscles.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
                            Text("SECONDARY MUSCLES")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textTertiary)
                                .tracking(1)

                            ForEach(exercise.secondaryMuscles, id: \.self) { activation in
                                HStack {
                                    Circle().fill(activation.muscle.color).frame(width: 10, height: 10)
                                    Text(activation.muscle.displayName)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundColor(AppTheme.textSecondary)
                                    Spacer()
                                    Text("\(Int(activation.activationPercent * 100))%")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(AppTheme.warning)

                                    ProgressBar(
                                        progress: activation.activationPercent,
                                        color: activation.muscle.color,
                                        height: 4
                                    )
                                    .frame(width: 60)
                                }
                                .padding(AppTheme.paddingSM)
                                .background(activation.muscle.color.opacity(0.05))
                                .cornerRadius(AppTheme.radiusSM)
                            }
                        }
                    }

                    // Instructions
                    if let instructions = exercise.instructions, !instructions.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
                            Text("INSTRUCTIONS")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textTertiary)
                                .tracking(1)

                            Text(instructions)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.textSecondary)
                                .lineSpacing(4)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.paddingMD)
                .padding(.bottom, AppTheme.paddingXL)
            }
            .background(AppTheme.background)
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }
}
