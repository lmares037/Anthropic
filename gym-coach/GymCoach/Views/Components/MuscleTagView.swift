import SwiftUI

/// Small colored tag showing a muscle group name.
struct MuscleTag: View {
    let muscle: MuscleGroup
    let activation: Double // 1.0 = primary, 0.5-0.75 = secondary

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(muscle.color)
                .frame(width: 6, height: 6)

            Text(muscle.displayName)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(activation >= 1.0 ? AppTheme.textPrimary : AppTheme.textSecondary)

            if activation < 1.0 {
                Text("\(Int(activation * 100))%")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(muscle.color.opacity(0.12))
        .cornerRadius(6)
    }
}

/// Flow layout showing all muscle tags for an exercise.
struct MuscleTagsFlow: View {
    let activations: [MuscleActivation]

    var body: some View {
        FlowLayout(spacing: 4) {
            ForEach(activations, id: \.self) { activation in
                MuscleTag(muscle: activation.muscle, activation: activation.activationPercent)
            }
        }
    }
}

/// Simple flow layout for wrapping tags.
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(
                x: bounds.minX + position.x,
                y: bounds.minY + position.y
            ), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}
