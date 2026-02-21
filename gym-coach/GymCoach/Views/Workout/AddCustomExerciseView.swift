import SwiftUI

struct AddCustomExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var category: ExerciseCategory = .custom
    @State private var equipment: EquipmentType = .none
    @State private var primaryMuscles: Set<MuscleGroup> = []
    @State private var secondaryMuscles: [MuscleGroup: Double] = [:]
    @State private var instructions = ""
    @State private var isLookingUp = false
    @State private var apiError: String?

    let onSave: (Exercise) -> Void

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !primaryMuscles.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.paddingLG) {
                    nameSection
                    categorySection
                    equipmentSection
                    apiLookupSection
                    primaryMuscleSection
                    secondaryMuscleSection
                    instructionsSection
                }
                .padding(.horizontal, AppTheme.paddingMD)
                .padding(.bottom, 100)
            }
            .background(AppTheme.background)
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveExercise() }
                        .foregroundColor(canSave ? AppTheme.accent : AppTheme.textTertiary)
                        .disabled(!canSave)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
            }
        }
    }

    // MARK: - Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            sectionHeader("Exercise Name")

            TextField("e.g. Cable Crossover", text: $name)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .padding(AppTheme.paddingSM + 4)
                .background(AppTheme.surface)
                .cornerRadius(AppTheme.radiusSM)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusSM)
                        .stroke(AppTheme.surfaceBorder, lineWidth: 1)
                )
                .autocorrectionDisabled()
        }
    }

    // MARK: - Category

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            sectionHeader("Category")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.paddingSM) {
                    ForEach(ExerciseCategory.allCases) { cat in
                        FilterPill(
                            title: cat.displayName,
                            icon: cat.icon,
                            isSelected: category == cat,
                            color: AppTheme.accent
                        ) {
                            category = cat
                        }
                    }
                }
            }
        }
    }

    // MARK: - Equipment

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            sectionHeader("Equipment")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(EquipmentType.allCases, id: \.rawValue) { equip in
                    Button {
                        equipment = equip
                    } label: {
                        Text(equip.displayName)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(equipment == equip ? .white : AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(equipment == equip ? AppTheme.accent : AppTheme.surface)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(equipment == equip ? AppTheme.accent : AppTheme.surfaceBorder, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    // MARK: - API Lookup

    private var apiLookupSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            Button {
                lookupMuscles()
            } label: {
                HStack(spacing: AppTheme.paddingSM) {
                    if isLookingUp {
                        ProgressView()
                            .tint(AppTheme.accentSecondary)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                    }
                    Text(isLookingUp ? "Looking up muscles..." : "Auto-detect muscles from name")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Spacer()
                }
                .foregroundColor(AppTheme.accentSecondary)
                .padding(AppTheme.paddingSM + 4)
                .background(AppTheme.accentSecondary.opacity(0.1))
                .cornerRadius(AppTheme.radiusSM)
            }
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isLookingUp)

            if let error = apiError {
                Text(error)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.danger)
            }
        }
    }

    // MARK: - Primary Muscles

    private var primaryMuscleSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            sectionHeader("Primary Muscles (100% activation)")

            FlowLayout(spacing: 6) {
                ForEach(MuscleGroup.allCases) { muscle in
                    Button {
                        if primaryMuscles.contains(muscle) {
                            primaryMuscles.remove(muscle)
                        } else {
                            primaryMuscles.insert(muscle)
                            secondaryMuscles.removeValue(forKey: muscle)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(muscle.color)
                                .frame(width: 8, height: 8)
                            Text(muscle.displayName)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(primaryMuscles.contains(muscle) ? .white : AppTheme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(primaryMuscles.contains(muscle) ? muscle.color.opacity(0.8) : AppTheme.surface)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(primaryMuscles.contains(muscle) ? muscle.color : AppTheme.surfaceBorder, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Secondary Muscles

    private var secondaryMuscleSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            sectionHeader("Secondary Muscles (50-75% activation)")

            let availableMuscles = MuscleGroup.allCases.filter { !primaryMuscles.contains($0) }

            FlowLayout(spacing: 6) {
                ForEach(availableMuscles) { muscle in
                    Button {
                        if secondaryMuscles[muscle] != nil {
                            secondaryMuscles.removeValue(forKey: muscle)
                        } else {
                            secondaryMuscles[muscle] = 0.5
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(muscle.color)
                                .frame(width: 8, height: 8)
                            Text(muscle.displayName)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                            if let pct = secondaryMuscles[muscle] {
                                Text("\(Int(pct * 100))%")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                            }
                        }
                        .foregroundColor(secondaryMuscles[muscle] != nil ? .white : AppTheme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(secondaryMuscles[muscle] != nil ? muscle.color.opacity(0.5) : AppTheme.surface)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(secondaryMuscles[muscle] != nil ? muscle.color.opacity(0.6) : AppTheme.surfaceBorder, lineWidth: 1)
                        )
                    }
                }
            }

            // Activation sliders for selected secondary muscles
            ForEach(secondaryMuscles.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { muscle in
                HStack {
                    Circle()
                        .fill(muscle.color)
                        .frame(width: 8, height: 8)
                    Text(muscle.displayName)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 80, alignment: .leading)

                    Slider(
                        value: Binding(
                            get: { secondaryMuscles[muscle] ?? 0.5 },
                            set: { secondaryMuscles[muscle] = $0 }
                        ),
                        in: 0.5...0.75,
                        step: 0.05
                    )
                    .tint(muscle.color)

                    Text("\(Int((secondaryMuscles[muscle] ?? 0.5) * 100))%")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 36)
                }
            }
        }
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            sectionHeader("Instructions (optional)")

            TextField("How to perform this exercise...", text: $instructions, axis: .vertical)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(3...6)
                .padding(AppTheme.paddingSM + 4)
                .background(AppTheme.surface)
                .cornerRadius(AppTheme.radiusSM)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusSM)
                        .stroke(AppTheme.surfaceBorder, lineWidth: 1)
                )
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(AppTheme.textTertiary)
            .tracking(1)
    }

    private func saveExercise() {
        let secondaryActivations = secondaryMuscles.map { muscle, percent in
            MuscleActivation(muscle: muscle, activationPercent: percent)
        }

        let exercise = Exercise(
            name: name.trimmingCharacters(in: .whitespaces),
            category: category,
            equipment: equipment,
            primaryMuscles: Array(primaryMuscles),
            secondaryMuscles: secondaryActivations,
            isCustom: true,
            instructions: instructions.isEmpty ? nil : instructions
        )

        onSave(exercise)
        dismiss()
    }

    /// Calls the ExerciseDB API to auto-detect muscles from exercise name.
    private func lookupMuscles() {
        isLookingUp = true
        apiError = nil

        Task {
            do {
                let results = try await ExerciseAPIService.shared.searchExercise(name: name)
                if let match = results.first {
                    await MainActor.run {
                        // Map primary target (handles both v1 `target` and v2 `targetMuscles`)
                        if let targetName = match.primaryTarget,
                           let primary = ExerciseAPIService.mapToMuscleGroup(targetName) {
                            primaryMuscles.insert(primary)
                        }

                        // Map secondary muscles
                        for secondary in match.allSecondaryMuscles {
                            if let muscle = ExerciseAPIService.mapToMuscleGroup(secondary),
                               !primaryMuscles.contains(muscle) {
                                secondaryMuscles[muscle] = 0.5
                            }
                        }

                        // If we found instructions, pre-fill them
                        if let instr = match.instructions, !instr.isEmpty, instructions.isEmpty {
                            instructions = instr.joined(separator: "\n")
                        }

                        isLookingUp = false
                    }
                } else {
                    await MainActor.run {
                        apiError = "No matching exercise found. Select muscles manually."
                        isLookingUp = false
                    }
                }
            } catch {
                await MainActor.run {
                    apiError = error.localizedDescription
                    isLookingUp = false
                }
            }
        }
    }
}
