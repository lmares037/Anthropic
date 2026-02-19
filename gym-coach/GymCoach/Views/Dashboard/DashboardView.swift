import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \WorkoutLog.date, order: .reverse) private var allLogs: [WorkoutLog]
    @State private var viewModel = WorkoutViewModel()

    private var weeklyTotals: [MuscleGroup: Double] {
        viewModel.weeklyEffectiveSets(from: allLogs)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.paddingLG) {
                    headerSection
                    weekSummaryCard
                    muscleGroupGrid
                }
                .padding(.horizontal, AppTheme.paddingMD)
                .padding(.bottom, AppTheme.paddingXL)
            }
            .background(AppTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("GYM COACH")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.accent)
                        .tracking(2)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            Text("Weekly Volume")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)

            Text("Track your effective sets per muscle group")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)

            Text("Target: 12-20 sets/week for hypertrophy")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AppTheme.paddingSM)
    }

    // MARK: - Week Summary

    private var weekSummaryCard: some View {
        let optimal = MuscleGroup.allCases.filter { (weeklyTotals[$0] ?? 0) >= 12 && (weeklyTotals[$0] ?? 0) <= 20 }.count
        let total = MuscleGroup.allCases.count
        let totalSets = weeklyTotals.values.reduce(0, +)

        return HStack(spacing: AppTheme.paddingLG) {
            VStack(spacing: 4) {
                Text("\(optimal)/\(total)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.success)
                Text("Optimal")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
            }

            Rectangle()
                .fill(AppTheme.surfaceBorder)
                .frame(width: 1, height: 40)

            VStack(spacing: 4) {
                Text(String(format: "%.0f", totalSets))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.accent)
                Text("Total Sets")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
            }

            Rectangle()
                .fill(AppTheme.surfaceBorder)
                .frame(width: 1, height: 40)

            VStack(spacing: 4) {
                Text("\(allLogs.filter { isThisWeek($0.date) }.count)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.accentSecondary)
                Text("Workouts")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    // MARK: - Muscle Group Grid

    private var muscleGroupGrid: some View {
        VStack(spacing: AppTheme.paddingSM) {
            ForEach(MuscleCategory.allCases, id: \.rawValue) { category in
                VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
                    Text(category.rawValue.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textTertiary)
                        .tracking(1.5)
                        .padding(.leading, 4)

                    let muscles = MuscleGroup.allCases.filter { $0.category == category }
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: AppTheme.paddingSM),
                        GridItem(.flexible(), spacing: AppTheme.paddingSM)
                    ], spacing: AppTheme.paddingSM) {
                        ForEach(muscles) { muscle in
                            MuscleGroupCard(
                                muscle: muscle,
                                effectiveSets: weeklyTotals[muscle] ?? 0,
                                viewModel: viewModel
                            )
                        }
                    }
                }
            }
        }
    }

    private func isThisWeek(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: .now, toGranularity: .weekOfYear)
    }
}

// MARK: - Muscle Group Card

struct MuscleGroupCard: View {
    let muscle: MuscleGroup
    let effectiveSets: Double
    let viewModel: WorkoutViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            HStack {
                Image(systemName: muscle.icon)
                    .font(.system(size: 14))
                    .foregroundColor(muscle.color)

                Spacer()

                ProgressRing(
                    progress: viewModel.progress(for: muscle, effectiveSets: effectiveSets),
                    color: viewModel.statusColor(for: effectiveSets),
                    size: 32,
                    lineWidth: 3
                )
            }

            Text(muscle.displayName)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", effectiveSets))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(viewModel.statusColor(for: effectiveSets))

                Text("/ \(Int(MuscleGroup.minSetsPerWeek))-\(Int(MuscleGroup.maxSetsPerWeek))")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
            }

            ProgressBar(
                progress: viewModel.progress(for: muscle, effectiveSets: effectiveSets),
                color: viewModel.statusColor(for: effectiveSets),
                height: 4
            )

            Text(viewModel.statusLabel(for: effectiveSets))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(viewModel.statusColor(for: effectiveSets))
        }
        .cardStyle()
    }
}
