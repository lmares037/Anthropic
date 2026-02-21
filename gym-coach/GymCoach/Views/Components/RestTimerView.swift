import SwiftUI

/// A rest timer with preset durations for between-set recovery.
struct RestTimerView: View {
    @State private var selectedDuration: Int = 90
    @State private var timeRemaining: Int = 0
    @State private var isRunning = false
    @State private var timer: Timer?

    /// Recommended rest durations by training goal
    private let presets: [(label: String, seconds: Int, description: String)] = [
        ("30s", 30, "Endurance"),
        ("60s", 60, "Fat Loss"),
        ("90s", 90, "Hypertrophy"),
        ("2m", 120, "Strength"),
        ("3m", 180, "Power"),
        ("5m", 300, "Max Effort"),
    ]

    var body: some View {
        VStack(spacing: AppTheme.paddingSM) {
            // Header
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.accentSecondary)
                Text("REST TIMER")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
                    .tracking(1.5)
                Spacer()
                if isRunning {
                    Text("Resting...")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.accentSecondary)
                }
            }

            // Timer display
            ZStack {
                // Background ring
                Circle()
                    .stroke(AppTheme.surfaceBorder, lineWidth: 6)

                // Progress ring
                Circle()
                    .trim(from: 0, to: timerProgress)
                    .stroke(
                        timerColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: timerProgress)

                VStack(spacing: 2) {
                    Text(formattedTime)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(isRunning ? timerColor : AppTheme.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: timeRemaining)

                    if !isRunning && timeRemaining == 0 {
                        Text("Tap to start")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.textTertiary)
                    } else if timeRemaining == 0 && !isRunning {
                        Text("Done!")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.success)
                    }
                }
            }
            .frame(width: 130, height: 130)
            .onTapGesture {
                if isRunning {
                    stopTimer()
                } else {
                    startTimer()
                }
            }

            // Preset buttons
            VStack(spacing: AppTheme.paddingXS) {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: AppTheme.paddingXS),
                    GridItem(.flexible(), spacing: AppTheme.paddingXS),
                    GridItem(.flexible(), spacing: AppTheme.paddingXS),
                ], spacing: AppTheme.paddingXS) {
                    ForEach(presets, id: \.seconds) { preset in
                        Button {
                            selectPreset(preset.seconds)
                        } label: {
                            VStack(spacing: 2) {
                                Text(preset.label)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedDuration == preset.seconds ? AppTheme.accentSecondary : AppTheme.textPrimary)
                                Text(preset.description)
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                selectedDuration == preset.seconds
                                    ? AppTheme.accentSecondary.opacity(0.15)
                                    : AppTheme.surfaceElevated.opacity(0.5)
                            )
                            .cornerRadius(AppTheme.radiusSM)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.radiusSM)
                                    .stroke(
                                        selectedDuration == preset.seconds
                                            ? AppTheme.accentSecondary.opacity(0.4)
                                            : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                }
            }
        }
        .cardStyle()
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Computed

    private var timerProgress: Double {
        guard selectedDuration > 0 else { return 0 }
        if !isRunning && timeRemaining == 0 { return 0 }
        return Double(timeRemaining) / Double(selectedDuration)
    }

    private var timerColor: Color {
        let ratio = Double(timeRemaining) / Double(max(selectedDuration, 1))
        if ratio > 0.5 { return AppTheme.accentSecondary }
        if ratio > 0.2 { return AppTheme.warning }
        return AppTheme.danger
    }

    private var formattedTime: String {
        let display = isRunning || timeRemaining > 0 ? timeRemaining : selectedDuration
        let minutes = display / 60
        let seconds = display % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return "\(seconds)"
    }

    // MARK: - Actions

    private func selectPreset(_ seconds: Int) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        stopTimer()
        selectedDuration = seconds
        timeRemaining = 0
    }

    private func startTimer() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        timeRemaining = selectedDuration
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.success)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
}
