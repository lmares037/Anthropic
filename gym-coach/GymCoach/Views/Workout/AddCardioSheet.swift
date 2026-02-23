import SwiftUI

/// Sheet for adding a time-based cardio workout (walking, running, boxing).
struct AddCardioSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var activityType: CardioActivityType = .running
    @State private var hours: Int = 0
    @State private var minutes: Int = 30
    @State private var seconds: Int = 0
    @State private var distanceKm: String = ""
    @State private var avgHeartRate: String = ""
    @State private var manualIntensity: Double?
    @State private var showIntensitySlider = false

    let onAdd: (CardioEntry) -> Void

    private var durationSeconds: Double {
        Double(hours * 3600 + minutes * 60 + seconds)
    }

    private var previewIntensity: Double {
        if let manual = manualIntensity { return manual }
        return CardioIntensity.calculate(
            activity: activityType,
            durationSeconds: durationSeconds,
            distanceMeters: distanceInMeters,
            avgHeartRate: heartRateValue
        )
    }

    private var distanceInMeters: Double? {
        guard let km = Double(distanceKm), km > 0 else { return nil }
        return km * 1000.0
    }

    private var heartRateValue: Double? {
        guard let hr = Double(avgHeartRate), hr > 0 else { return nil }
        return hr
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.paddingLG) {
                    activityPicker
                    durationPicker
                    metricsSection
                    intensityPreview
                    addButton
                }
                .padding(.horizontal, AppTheme.paddingMD)
                .padding(.bottom, AppTheme.paddingXL)
            }
            .background(AppTheme.background)
            .navigationTitle("Add Cardio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Activity Picker

    private var activityPicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            Text("ACTIVITY")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textTertiary)
                .tracking(1.5)

            HStack(spacing: AppTheme.paddingSM) {
                ForEach(CardioActivityType.allCases) { type in
                    Button {
                        withAnimation { activityType = type }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: type.icon)
                                .font(.system(size: 24))
                            Text(type.displayName)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(activityType == type ? .white : AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(activityType == type ? AppTheme.accent : AppTheme.surface)
                        .cornerRadius(AppTheme.radiusMD)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                                .stroke(activityType == type ? AppTheme.accent : AppTheme.surfaceBorder, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Duration Picker

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            Text("DURATION")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textTertiary)
                .tracking(1.5)

            HStack(spacing: AppTheme.paddingSM) {
                durationWheel(value: $hours, range: 0...5, label: "hr")
                durationWheel(value: $minutes, range: 0...59, label: "min")
                durationWheel(value: $seconds, range: 0...59, label: "sec")
            }
            .padding(AppTheme.paddingSM)
            .background(AppTheme.surface)
            .cornerRadius(AppTheme.radiusMD)
        }
    }

    private func durationWheel(value: Binding<Int>, range: ClosedRange<Int>, label: String) -> some View {
        VStack(spacing: 4) {
            Picker(label, selection: value) {
                ForEach(range, id: \.self) { n in
                    Text("\(n)").tag(n)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)

            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.textTertiary)
        }
    }

    // MARK: - Metrics

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            Text("METRICS (OPTIONAL)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textTertiary)
                .tracking(1.5)

            if activityType == .walking || activityType == .running {
                HStack {
                    Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 24)
                    TextField("Distance (km)", text: $distanceKm)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .padding(AppTheme.paddingSM + 4)
                .background(AppTheme.surface)
                .cornerRadius(AppTheme.radiusSM)

                if let pace = computedPace {
                    HStack(spacing: 4) {
                        Image(systemName: "speedometer")
                            .font(.system(size: 11))
                        Text("Pace: \(pace)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(AppTheme.accentSecondary)
                }
            }

            if activityType == .boxing {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(AppTheme.danger)
                        .frame(width: 24)
                    TextField("Avg Heart Rate (bpm)", text: $avgHeartRate)
                        .keyboardType(.numberPad)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .padding(AppTheme.paddingSM + 4)
                .background(AppTheme.surface)
                .cornerRadius(AppTheme.radiusSM)

                Text("Heart rate is used to calculate intensity. Leave blank to estimate from duration.")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
    }

    private var computedPace: String? {
        guard let dist = distanceInMeters, dist > 0, durationSeconds > 0 else { return nil }
        let paceMinPerKm = (durationSeconds / 60.0) / (dist / 1000.0)
        let mins = Int(paceMinPerKm)
        let secs = Int((paceMinPerKm - Double(mins)) * 60)
        return String(format: "%d:%02d /km", mins, secs)
    }

    // MARK: - Intensity Preview

    private var intensityPreview: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSM) {
            HStack {
                Text("INTENSITY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
                    .tracking(1.5)

                Spacer()

                Button {
                    withAnimation {
                        if showIntensitySlider {
                            // Reset to auto
                            manualIntensity = nil
                            showIntensitySlider = false
                        } else {
                            manualIntensity = previewIntensity
                            showIntensitySlider = true
                        }
                    }
                } label: {
                    Text(showIntensitySlider ? "Auto-detect" : "Adjust")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.accentSecondary)
                }
            }

            // Intensity bar
            VStack(spacing: AppTheme.paddingSM) {
                HStack {
                    Text(CardioIntensity.label(for: previewIntensity))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(intensityColor)

                    Spacer()

                    Text("\(Int(previewIntensity * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(intensityColor)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.surfaceBorder)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(intensityColor)
                            .frame(width: geo.size.width * previewIntensity, height: 8)
                    }
                }
                .frame(height: 8)

                if showIntensitySlider {
                    Slider(
                        value: Binding(
                            get: { manualIntensity ?? previewIntensity },
                            set: { manualIntensity = $0 }
                        ),
                        in: 0.1...1.0,
                        step: 0.05
                    )
                    .tint(intensityColor)
                }

                // Effective sets preview
                let effectiveSets = CardioIntensity.effectiveSets(
                    activity: activityType,
                    durationSeconds: durationSeconds,
                    intensity: previewIntensity
                )
                if !effectiveSets.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Equivalent volume:")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.textTertiary)

                        HStack(spacing: 8) {
                            ForEach(effectiveSets.sorted(by: { $0.value > $1.value }), id: \.key) { muscle, sets in
                                HStack(spacing: 2) {
                                    Circle().fill(muscle.color).frame(width: 5, height: 5)
                                    Text("\(muscle.displayName) \(String(format: "%.1f", sets))")
                                        .font(.system(size: 9, weight: .medium, design: .rounded))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(AppTheme.paddingSM + 4)
            .background(AppTheme.surface)
            .cornerRadius(AppTheme.radiusMD)
        }
    }

    private var intensityColor: Color {
        switch previewIntensity {
        case ..<0.45: return AppTheme.success
        case 0.45..<0.65: return AppTheme.warning
        default: return AppTheme.danger
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            let entry = CardioEntry(
                activityType: activityType,
                durationSeconds: durationSeconds,
                distanceMeters: distanceInMeters,
                avgHeartRate: heartRateValue,
                intensity: manualIntensity
            )
            onAdd(entry)
            dismiss()
        } label: {
            HStack(spacing: AppTheme.paddingSM) {
                Image(systemName: activityType.icon)
                Text("Add \(activityType.displayName)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(durationSeconds > 0 ? AppTheme.accent : AppTheme.surfaceBorder)
            .cornerRadius(AppTheme.radiusMD)
        }
        .disabled(durationSeconds <= 0)
    }
}
