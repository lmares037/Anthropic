import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(sort: \WorkoutLog.date, order: .reverse) private var allLogs: [WorkoutLog]
    @Query private var allExercises: [Exercise]

    // User stats (could be made editable / stored in UserDefaults)
    @AppStorage("userName") private var userName = "Coach"
    @AppStorage("userWeight") private var userWeight = 185.0
    @AppStorage("userHeight") private var userHeight = "5'10\""
    @AppStorage("userBodyFat") private var userBodyFat = 19.5
    @AppStorage("userAge") private var userAge = 33

    @State private var showEditProfile = false
    @State private var iconExported = false
    @State private var iconShareURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.paddingLG) {
                    profileHeader
                    statsGrid
                    bodyCompSection
                    allTimeStats
                    exportIconSection
                }
                .padding(.horizontal, AppTheme.paddingMD)
                .padding(.bottom, AppTheme.paddingXL)
            }
            .background(AppTheme.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: Binding(
                get: { iconShareURL != nil },
                set: { if !$0 { iconShareURL = nil } }
            )) {
                if let url = iconShareURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    // MARK: - Export Icon

    private var exportIconSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            Text("APP ICON")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textTertiary)
                .tracking(1.5)

            // Icon preview
            HStack(spacing: AppTheme.paddingMD) {
                AppIconView(size: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Gym Coach Icon")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Export the generated icon to set as your app icon in Xcode")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textTertiary)
                }

                Spacer()
            }

            Button {
                Task {
                    if let url = await IconExporter.forceExport() {
                        iconShareURL = url
                        iconExported = true
                    }
                }
            } label: {
                HStack(spacing: AppTheme.paddingSM) {
                    Image(systemName: iconExported ? "checkmark.circle.fill" : "square.and.arrow.up")
                        .font(.system(size: 14))
                    Text(iconExported ? "Exported — Tap to Share Again" : "Export App Icon (1024x1024)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(AppTheme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AppTheme.accent.opacity(0.1))
                .cornerRadius(AppTheme.radiusSM)
            }
        }
        .cardStyle()
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: AppTheme.paddingMD) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accent, AppTheme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                Text(String(userName.prefix(1)).uppercased())
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)

                Text("Body Recomposition")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.accent)

                Text("Goal: Lean physique with visible muscle")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
            }

            Spacer()
        }
        .cardStyle()
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppTheme.paddingSM) {
            StatCard(value: "\(userAge)", label: "Age")
            StatCard(value: String(format: "%.0f", userWeight), unit: "lbs", label: "Weight")
            StatCard(value: userHeight, label: "Height")
            StatCard(value: String(format: "%.1f%%", userBodyFat), label: "Body Fat")
        }
    }

    // MARK: - Body Comp

    private var bodyCompSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            Text("BODY COMPOSITION")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textTertiary)
                .tracking(1.5)

            let leanMass = userWeight * (1 - userBodyFat / 100)
            let fatMass = userWeight * (userBodyFat / 100)

            HStack(spacing: AppTheme.paddingMD) {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", leanMass))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.success)
                    Text("Lean Mass (lbs)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textTertiary)
                }

                Spacer()

                // Visual bar
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.success)
                            .frame(width: geo.size.width * (1 - userBodyFat / 100))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.warning)
                            .frame(width: geo.size.width * (userBodyFat / 100))
                    }
                }
                .frame(height: 12)
                .frame(maxWidth: 120)

                Spacer()

                VStack(spacing: 4) {
                    Text(String(format: "%.1f", fatMass))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.warning)
                    Text("Fat Mass (lbs)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - All Time Stats

    private var allTimeStats: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            Text("ALL TIME")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textTertiary)
                .tracking(1.5)

            let totalWorkouts = allLogs.count
            let totalExercisesLogged = allLogs.flatMap { $0.entries }.count
            let totalSets = allLogs.flatMap { $0.entries }.reduce(0) { $0 + $1.sets }
            let customExercises = allExercises.filter { $0.isCustom }.count

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.paddingSM) {
                AllTimeStatRow(icon: "calendar", value: "\(totalWorkouts)", label: "Workouts")
                AllTimeStatRow(icon: "figure.strengthtraining.traditional", value: "\(totalExercisesLogged)", label: "Exercises Logged")
                AllTimeStatRow(icon: "number", value: "\(totalSets)", label: "Total Sets")
                AllTimeStatRow(icon: "plus.circle", value: "\(customExercises)", label: "Custom Exercises")
            }
        }
        .cardStyle()
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: String
    var unit: String?
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                if let unit {
                    Text(unit)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.paddingSM + 4)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.radiusSM)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusSM)
                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
        )
    }
}

struct AllTimeStatRow: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: AppTheme.paddingSM) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.accent)
                .frame(width: 28, height: 28)
                .background(AppTheme.accent.opacity(0.12))
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
            }
            Spacer()
        }
        .padding(AppTheme.paddingSM)
        .background(AppTheme.surfaceElevated.opacity(0.5))
        .cornerRadius(AppTheme.radiusSM)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
