import SwiftUI

/// Main view of the watchOS companion app.
/// Shows quick-start buttons for supported activities and active workout status.
struct WatchHomeView: View {
    @EnvironmentObject var workoutManager: WatchWorkoutManager

    var body: some View {
        NavigationStack {
            if workoutManager.isWorkoutActive {
                ActiveWorkoutView()
            } else {
                startView
            }
        }
    }

    private var startView: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Gym Coach")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Start a workout to auto-sync with your iPhone")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 4)

                ActivityButton(
                    title: "Walking",
                    icon: "figure.walk",
                    color: .green,
                    activityType: "walking"
                )

                ActivityButton(
                    title: "Running",
                    icon: "figure.run",
                    color: .blue,
                    activityType: "running"
                )

                ActivityButton(
                    title: "Boxing",
                    icon: "figure.boxing",
                    color: .red,
                    activityType: "boxing"
                )
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Activity Button

struct ActivityButton: View {
    @EnvironmentObject var workoutManager: WatchWorkoutManager

    let title: String
    let icon: String
    let color: Color
    let activityType: String

    var body: some View {
        Button {
            Task {
                await workoutManager.startWorkout(activityType: activityType)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.2))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Tap to start")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(10)
            .background(Color(white: 0.15))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
