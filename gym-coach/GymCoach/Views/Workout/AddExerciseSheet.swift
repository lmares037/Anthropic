import SwiftUI
import SwiftData

struct AddExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var selectedMuscle: MuscleGroup?
    @State private var showAddCustom = false

    let onSelect: (Exercise) -> Void

    /// Exercises sorted with recently used first, then alphabetical.
    private var sortedExercises: [Exercise] {
        let filtered = allExercises.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText)

            let matchesCategory = selectedCategory == nil ||
                exercise.category == selectedCategory

            let matchesMuscle = selectedMuscle == nil ||
                exercise.primaryMuscles.contains(selectedMuscle!) ||
                exercise.secondaryMuscles.contains { $0.muscle == selectedMuscle! }

            return matchesSearch && matchesCategory && matchesMuscle
        }

        return filtered.sorted { a, b in
            // Recently used exercises come first
            if let aDate = a.lastUsedDate, let bDate = b.lastUsedDate {
                return aDate > bDate
            }
            if a.lastUsedDate != nil { return true }
            if b.lastUsedDate != nil { return false }
            // Then by use count
            if a.useCount != b.useCount { return a.useCount > b.useCount }
            // Then alphabetical
            return a.name < b.name
        }
    }

    private var recentExercises: [Exercise] {
        sortedExercises.filter { $0.lastUsedDate != nil }.prefix(5).map { $0 }
    }

    private var otherExercises: [Exercise] {
        sortedExercises.filter { $0.lastUsedDate == nil || !recentExercises.contains(where: { $0.id == $0.id }) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.paddingMD) {
                    // Search bar
                    searchBar

                    // Category filter pills
                    categoryFilter

                    // Muscle filter pills
                    muscleFilter

                    // Add custom exercise button
                    addCustomButton

                    // Recent exercises section
                    if !recentExercises.isEmpty && searchText.isEmpty && selectedCategory == nil && selectedMuscle == nil {
                        recentSection
                    }

                    // All exercises
                    exerciseList
                }
                .padding(.horizontal, AppTheme.paddingMD)
                .padding(.bottom, AppTheme.paddingXL)
            }
            .background(AppTheme.background)
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .sheet(isPresented: $showAddCustom) {
                AddCustomExerciseView { exercise in
                    modelContext.insert(exercise)
                    onSelect(exercise)
                    dismiss()
                }
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
                Button {
                    searchText = ""
                } label: {
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

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.paddingSM) {
                FilterPill(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    color: AppTheme.accent
                ) {
                    selectedCategory = nil
                }

                ForEach(ExerciseCategory.allCases) { cat in
                    FilterPill(
                        title: cat.displayName,
                        icon: cat.icon,
                        isSelected: selectedCategory == cat,
                        color: AppTheme.accent
                    ) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
        }
    }

    // MARK: - Muscle Filter

    private var muscleFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(MuscleGroup.allCases) { muscle in
                    FilterPill(
                        title: muscle.displayName,
                        isSelected: selectedMuscle == muscle,
                        color: muscle.color
                    ) {
                        selectedMuscle = selectedMuscle == muscle ? nil : muscle
                    }
                }
            }
        }
    }

    // MARK: - Add Custom

    private var addCustomButton: some View {
        Button {
            showAddCustom = true
        } label: {
            HStack(spacing: AppTheme.paddingSM) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                Text("Create Custom Exercise")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
            }
            .foregroundColor(AppTheme.accentSecondary)
            .padding(AppTheme.paddingSM + 4)
            .background(AppTheme.accentSecondary.opacity(0.1))
            .cornerRadius(AppTheme.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                    .stroke(AppTheme.accentSecondary.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Recent Section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            Text("RECENT")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textTertiary)
                .tracking(1.5)

            ForEach(recentExercises) { exercise in
                ExerciseSelectRow(exercise: exercise) {
                    onSelect(exercise)
                    dismiss()
                }
            }
        }
    }

    // MARK: - Exercise List

    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            if !recentExercises.isEmpty && searchText.isEmpty && selectedCategory == nil && selectedMuscle == nil {
                Text("ALL EXERCISES")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
                    .tracking(1.5)
            }

            if sortedExercises.isEmpty {
                VStack(spacing: AppTheme.paddingSM) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.textTertiary)
                    Text("No exercises found")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary)
                    Text("Try a different search or create a custom exercise")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.paddingXL)
            } else {
                ForEach(sortedExercises) { exercise in
                    ExerciseSelectRow(exercise: exercise) {
                        onSelect(exercise)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Exercise Select Row

struct ExerciseSelectRow: View {
    let exercise: Exercise
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.paddingSM + 4) {
                // Category icon
                Image(systemName: exercise.category.icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.accent)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.accent.opacity(0.12))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(exercise.name)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)

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

                    // Compact muscle tags
                    HStack(spacing: 4) {
                        ForEach(exercise.primaryMuscles, id: \.self) { muscle in
                            HStack(spacing: 2) {
                                Circle().fill(muscle.color).frame(width: 5, height: 5)
                                Text(muscle.displayName)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                    }
                }

                Spacer()

                Image(systemName: "plus.circle")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.accent.opacity(0.6))
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
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? color : AppTheme.surface)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color : AppTheme.surfaceBorder, lineWidth: 1)
            )
        }
    }
}
