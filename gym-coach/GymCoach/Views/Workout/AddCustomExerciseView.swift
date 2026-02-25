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
    @State private var isDownloadingDB = false
    @State private var apiError: String?
    @State private var searchResults: [ExerciseAPIService.ExerciseResult] = []
    @State private var selectedResultIndex: Int?
    @State private var cacheReady = false

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
                .onChange(of: name) {
                    // Clear previous results when name changes
                    if !searchResults.isEmpty {
                        searchResults = []
                        selectedResultIndex = nil
                    }
                }
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
            // Download DB button (shown only if cache isn't ready)
            if !cacheReady {
                Button {
                    downloadDatabase()
                } label: {
                    HStack(spacing: AppTheme.paddingSM) {
                        if isDownloadingDB {
                            ProgressView()
                                .tint(AppTheme.accentSecondary)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 14))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isDownloadingDB ? "Downloading exercise database..." : "Download Exercise Database")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Text("One-time download (uses 1 API call). Enables offline search of 1300+ exercises.")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.textTertiary)
                        }
                        Spacer()
                    }
                    .foregroundColor(AppTheme.accentSecondary)
                    .padding(AppTheme.paddingSM + 4)
                    .background(AppTheme.accentSecondary.opacity(0.1))
                    .cornerRadius(AppTheme.radiusSM)
                }
                .disabled(isDownloadingDB)
            }

            // Search button (shown once cache is ready)
            if cacheReady {
                Button {
                    lookupMuscles()
                } label: {
                    HStack(spacing: AppTheme.paddingSM) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                        Text("Search exercises & auto-detect muscles")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Spacer()
                        Text("Local")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.success)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.success.opacity(0.15))
                            .cornerRadius(4)
                    }
                    .foregroundColor(AppTheme.accentSecondary)
                    .padding(AppTheme.paddingSM + 4)
                    .background(AppTheme.accentSecondary.opacity(0.1))
                    .cornerRadius(AppTheme.radiusSM)
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if let error = apiError {
                Text(error)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.danger)
            }

            // Search results list
            if !searchResults.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.paddingXS) {
                    HStack {
                        Text("\(searchResults.count) matches")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.accentSecondary)
                        Spacer()
                        Button {
                            withAnimation { searchResults = []; selectedResultIndex = nil }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.textTertiary)
                        }
                    }

                    ForEach(Array(searchResults.enumerated()), id: \.offset) { index, result in
                        searchResultRow(result, index: index)
                    }
                }
                .padding(AppTheme.paddingSM)
                .background(AppTheme.surface)
                .cornerRadius(AppTheme.radiusSM)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusSM)
                        .stroke(AppTheme.accentSecondary.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .task {
            // Check if cache exists on disk and load it into memory
            let hasCache = await ExerciseAPIService.shared.hasCacheOnDisk
            if hasCache {
                do {
                    try await ExerciseAPIService.shared.ensureCache()
                } catch {
                    return
                }
                cacheReady = true
            }
        }
    }

    // MARK: - Search Result Row

    private func searchResultRow(_ result: ExerciseAPIService.ExerciseResult, index: Int) -> some View {
        let isSelected = selectedResultIndex == index
        let primaryName = result.primaryTarget ?? "—"
        let secondaryNames = result.allSecondaryMuscles

        return Button {
            selectResult(result, at: index)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(result.exerciseName.capitalized)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? AppTheme.accentSecondary : AppTheme.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.accentSecondary)
                    }
                }

                // Target + equipment
                HStack(spacing: 6) {
                    if let equip = result.equipment {
                        Label(equip.capitalized, systemImage: "wrench.and.screwdriver")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    if let bodyPart = result.bodyPart ?? result.bodyParts?.first {
                        Label(bodyPart.capitalized, systemImage: "figure.run")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }

                // Muscle tags
                HStack(spacing: 4) {
                    if let mapped = ExerciseAPIService.mapToMuscleGroup(primaryName) {
                        musclePill(mapped.displayName, color: mapped.color, isPrimary: true)
                    } else {
                        musclePill(primaryName.capitalized, color: AppTheme.accent, isPrimary: true)
                    }

                    ForEach(secondaryNames.prefix(3), id: \.self) { sec in
                        if let mapped = ExerciseAPIService.mapToMuscleGroup(sec) {
                            musclePill(mapped.displayName, color: mapped.color, isPrimary: false)
                        }
                    }

                    if secondaryNames.count > 3 {
                        Text("+\(secondaryNames.count - 3)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background(isSelected ? AppTheme.accentSecondary.opacity(0.08) : Color.clear)
            .cornerRadius(6)
        }
    }

    private func musclePill(_ text: String, color: Color, isPrimary: Bool) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            Text(text)
                .font(.system(size: 9, weight: isPrimary ? .bold : .medium, design: .rounded))
                .foregroundColor(isPrimary ? color : AppTheme.textSecondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(isPrimary ? 0.15 : 0.08))
        .cornerRadius(4)
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

    /// Applies a selected API result to the form fields.
    private func selectResult(_ result: ExerciseAPIService.ExerciseResult, at index: Int) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        withAnimation(.spring(response: 0.3)) {
            selectedResultIndex = index

            // Fill name from the result
            name = result.exerciseName.capitalized

            // Map primary target
            primaryMuscles.removeAll()
            if let targetName = result.primaryTarget,
               let primary = ExerciseAPIService.mapToMuscleGroup(targetName) {
                primaryMuscles.insert(primary)
            }

            // Map secondary muscles
            secondaryMuscles.removeAll()
            for secondary in result.allSecondaryMuscles {
                if let muscle = ExerciseAPIService.mapToMuscleGroup(secondary),
                   !primaryMuscles.contains(muscle) {
                    secondaryMuscles[muscle] = 0.5
                }
            }

            // Pre-fill instructions if available and field is empty
            if let instr = result.instructions, !instr.isEmpty {
                instructions = instr.joined(separator: "\n")
            }
        }
    }

    /// Downloads the full exercise database (1 API call) and caches locally.
    private func downloadDatabase() {
        isDownloadingDB = true
        apiError = nil

        Task {
            do {
                try await ExerciseAPIService.shared.refreshCache()
                await MainActor.run {
                    cacheReady = true
                    isDownloadingDB = false
                }
            } catch {
                await MainActor.run {
                    apiError = error.localizedDescription
                    isDownloadingDB = false
                }
            }
        }
    }

    /// Searches the local exercise cache instantly (no API call).
    private func lookupMuscles() {
        searchResults = []
        selectedResultIndex = nil
        apiError = nil

        Task {
            do {
                try await ExerciseAPIService.shared.ensureCache()
            } catch {
                await MainActor.run {
                    apiError = "Could not load exercise database. Try downloading again."
                }
                return
            }

            let results = await ExerciseAPIService.shared.searchLocal(keyword: name)
            await MainActor.run {
                let limited = Array(results.prefix(20))
                if limited.isEmpty {
                    apiError = "No exercises found for \"\(name)\". Try a different keyword (e.g. \"press\", \"curl\", \"squat\", \"chest\", \"dumbbell\")."
                } else {
                    withAnimation { searchResults = limited }
                }
            }
        }
    }
}
