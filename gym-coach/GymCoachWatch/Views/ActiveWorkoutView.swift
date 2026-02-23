import SwiftUI

/// Shows live workout metrics during an active session on Apple Watch.
struct ActiveWorkoutView: View {
    @EnvironmentObject var workoutManager: WatchWorkoutManager

    var body: some View {
        VStack(spacing: 8) {
            // Activity header
            HStack(spacing: 6) {
                Image(systemName: activityIcon)
                    .foregroundColor(activityColor)
                Text(activityName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(activityColor)
            }

            // Timer
            Text(workoutManager.formattedElapsedTime)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            // Metrics
            HStack(spacing: 16) {
                if workoutManager.heartRate > 0 {
                    metricView(
                        icon: "heart.fill",
                        value: "\(Int(workoutManager.heartRate))",
                        unit: "bpm",
                        color: .red
                    )
                }

                if workoutManager.distance > 0 {
                    let km = workoutManager.distance / 1000.0
                    metricView(
                        icon: "point.bottomleft.forward.to.point.topright.scurvepath",
                        value: String(format: "%.2f", km),
                        unit: "km",
                        color: .blue
                    )
                }

                if workoutManager.calories > 0 {
                    metricView(
                        icon: "flame.fill",
                        value: "\(Int(workoutManager.calories))",
                        unit: "kcal",
                        color: .orange
                    )
                }
            }

            Spacer()

            // End button
            Button {
                Task {
                    await workoutManager.endWorkout()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "stop.fill")
                    Text("End")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.red)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            if workoutManager.isSynced {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                    Text("Synced to iPhone")
                        .font(.system(size: 10, design: .rounded))
                }
                .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 4)
    }

    private func metricView(icon: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Text(unit)
                .font(.system(size: 8, design: .rounded))
                .foregroundColor(.secondary)
        }
    }

    private var activityIcon: String {
        switch workoutManager.currentActivityType {
        case "running": return "figure.run"
        case "boxing": return "figure.boxing"
        default: return "figure.walk"
        }
    }

    private var activityName: String {
        switch workoutManager.currentActivityType {
        case "running": return "Running"
        case "boxing": return "Boxing"
        default: return "Walking"
        }
    }

    private var activityColor: Color {
        switch workoutManager.currentActivityType {
        case "running": return .blue
        case "boxing": return .red
        default: return .green
        }
    }
}
