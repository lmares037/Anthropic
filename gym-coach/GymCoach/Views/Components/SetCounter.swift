import SwiftUI

/// Plus/minus stepper for adjusting set counts.
/// Designed for one-thumb operation with large tap targets.
struct SetCounter: View {
    @Binding var sets: Int
    let minSets: Int
    let maxSets: Int

    init(sets: Binding<Int>, min: Int = 1, max: Int = 20) {
        self._sets = sets
        self.minSets = min
        self.maxSets = max
    }

    var body: some View {
        HStack(spacing: AppTheme.paddingSM) {
            // Minus button
            Button {
                if sets > minSets {
                    sets -= 1
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(sets > minSets ? AppTheme.textPrimary : AppTheme.textTertiary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(sets > minSets ? AppTheme.surfaceElevated : AppTheme.surface)
                    )
                    .overlay(
                        Circle()
                            .stroke(AppTheme.surfaceBorder, lineWidth: 1)
                    )
            }
            .disabled(sets <= minSets)

            // Set count display
            VStack(spacing: 0) {
                Text("\(sets)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: sets)

                Text("sets")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
            }
            .frame(width: 44)

            // Plus button
            Button {
                if sets < maxSets {
                    sets += 1
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(sets < maxSets ? AppTheme.textPrimary : AppTheme.textTertiary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(sets < maxSets ? AppTheme.accent.opacity(0.3) : AppTheme.surface)
                    )
                    .overlay(
                        Circle()
                            .stroke(sets < maxSets ? AppTheme.accent.opacity(0.5) : AppTheme.surfaceBorder, lineWidth: 1)
                    )
            }
            .disabled(sets >= maxSets)
        }
    }
}
