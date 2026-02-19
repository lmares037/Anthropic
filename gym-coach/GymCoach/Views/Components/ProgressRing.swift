import SwiftUI

/// Circular progress ring showing effective sets toward weekly target.
struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0+
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat

    init(progress: Double, color: Color, size: CGFloat = 50, lineWidth: CGFloat = 5) {
        self.progress = progress
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6), value: progress)

            // Overflow indicator (if > 100%)
            if progress > 1.0 {
                Circle()
                    .trim(from: 0, to: min(progress - 1.0, 1.0))
                    .stroke(
                        color.opacity(0.4),
                        style: StrokeStyle(lineWidth: lineWidth * 0.6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: progress)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Horizontal progress bar alternative for compact layouts.
struct ProgressBar: View {
    let progress: Double
    let color: Color
    let height: CGFloat

    init(progress: Double, color: Color, height: CGFloat = 6) {
        self.progress = progress
        self.color = color
        self.height = height
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color.opacity(0.15))

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geo.size.width * min(progress, 1.0))
                    .animation(.spring(response: 0.5), value: progress)
            }
        }
        .frame(height: height)
    }
}
