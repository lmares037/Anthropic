import SwiftUI
import Charts
import SwiftData

/// Shows weekly volume progress charts over the last 4 weeks.
struct ProgressChartsView: View {
    let allLogs: [WorkoutLog]
    let viewModel: WorkoutViewModel

    @State private var selectedCategory: MuscleCategory? = nil

    private var displayedMuscles: [MuscleGroup] {
        if let category = selectedCategory {
            return MuscleGroup.allCases.filter { $0.category == category }
        }
        return Array(MuscleGroup.allCases)
    }

    var body: some View {
        VStack(spacing: AppTheme.paddingMD) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.accent)
                Text("WEEKLY PROGRESS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
                    .tracking(1.5)
                Spacer()
            }

            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.paddingXS) {
                    categoryPill(label: "All", category: nil)
                    ForEach(MuscleCategory.allCases, id: \.rawValue) { category in
                        categoryPill(label: category.rawValue, category: category)
                    }
                }
            }

            // Weekly totals bar chart
            weeklyTotalsChart

            // Per-muscle sparklines
            muscleSparklines
        }
        .cardStyle()
    }

    // MARK: - Category Pill

    private func categoryPill(label: String, category: MuscleCategory?) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedCategory = category
            }
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(selectedCategory == category ? .white : AppTheme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(selectedCategory == category ? AppTheme.accent : AppTheme.surfaceElevated)
                .cornerRadius(12)
        }
    }

    // MARK: - Weekly Totals Chart

    private var weeklyTotalsChart: some View {
        let weekData = weeklyChartData()

        return VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            Text("Total Effective Sets by Week")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)

            Chart(weekData, id: \.weekLabel) { item in
                BarMark(
                    x: .value("Week", item.weekLabel),
                    y: .value("Sets", item.totalSets)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.accent, AppTheme.accentSecondary],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(AppTheme.surfaceBorder)
                    AxisValueLabel()
                        .foregroundStyle(AppTheme.textTertiary)
                        .font(.system(size: 9, design: .rounded))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(AppTheme.textSecondary)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                }
            }
            .chartPlotStyle { plotArea in
                plotArea.background(Color.clear)
            }
            .frame(height: 160)
        }
    }

    // MARK: - Muscle Sparklines

    private var muscleSparklines: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            Text("4-Week Muscle Trends")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)

            let weeklyData = (0..<4).reversed().map { offset -> (Int, [MuscleGroup: Double]) in
                let data = viewModel.weeklyEffectiveSets(from: allLogs, weekOffset: -offset)
                return (offset, data)
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AppTheme.paddingSM),
                GridItem(.flexible(), spacing: AppTheme.paddingSM),
            ], spacing: AppTheme.paddingSM) {
                ForEach(displayedMuscles) { muscle in
                    MuscleSparkline(
                        muscle: muscle,
                        weeklyData: weeklyData.map { ($0.0, $0.1[muscle] ?? 0) }
                    )
                }
            }
        }
    }

    // MARK: - Data

    private func weeklyChartData() -> [(weekLabel: String, totalSets: Double)] {
        let calendar = WorkoutViewModel.mondayCalendar
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        return (0..<4).reversed().map { offset in
            let data = viewModel.weeklyEffectiveSets(from: allLogs, weekOffset: -offset)
            let filteredTotal = displayedMuscles.reduce(0.0) { $0 + (data[$1] ?? 0) }
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -offset, to: Date()) ?? Date()
            let interval = calendar.dateInterval(of: .weekOfYear, for: weekStart)
            let label = formatter.string(from: interval?.start ?? weekStart)
            return (weekLabel: label, totalSets: filteredTotal)
        }
    }
}

// MARK: - Muscle Sparkline

struct MuscleSparkline: View {
    let muscle: MuscleGroup
    let weeklyData: [(weekOffset: Int, sets: Double)] // 4 weeks, newest last

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(muscle.color)
                    .frame(width: 6, height: 6)
                Text(muscle.displayName)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                let current = weeklyData.last?.sets ?? 0
                Text(String(format: "%.1f", current))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(statusColor(for: current))
            }

            Chart(Array(weeklyData.enumerated()), id: \.offset) { _, item in
                LineMark(
                    x: .value("Week", item.weekOffset),
                    y: .value("Sets", item.sets)
                )
                .foregroundStyle(muscle.color)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Week", item.weekOffset),
                    y: .value("Sets", item.sets)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [muscle.color.opacity(0.3), muscle.color.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartYScale(domain: 0...25)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartPlotStyle { plotArea in
                plotArea.background(Color.clear)
            }
            .frame(height: 40)

            // Optimal zone indicator
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(AppTheme.success.opacity(0.3))
                    .frame(height: 2)
                Text("12-20")
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding(AppTheme.paddingSM)
        .background(AppTheme.surfaceElevated.opacity(0.4))
        .cornerRadius(AppTheme.radiusSM)
    }

    private func statusColor(for sets: Double) -> Color {
        switch sets {
        case ..<8: return AppTheme.danger
        case 8..<12: return AppTheme.warning
        case 12...20: return AppTheme.success
        default: return AppTheme.accentSecondary
        }
    }
}
