import SwiftUI

/// App icon design: muscular arm curling a dumbbell.
/// This view can be previewed in Xcode and exported as the app icon.
struct AppIconView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "0A0A1A"),
                            Color(hex: "1A1035"),
                            Color(hex: "0A0A1A"),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Subtle radial glow behind arm
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "6C5CE7").opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.45
                    )
                )
                .offset(x: -size * 0.02, y: -size * 0.05)

            // Muscular arm + dumbbell composed from shapes
            Canvas { context, canvasSize in
                let s = canvasSize.width
                drawArm(context: context, size: s)
                drawDumbbell(context: context, size: s)
            }
            .frame(width: size * 0.75, height: size * 0.75)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }

    private func drawArm(context: GraphicsContext, size: CGFloat) {
        // Upper arm (from shoulder area going up to the bicep peak)
        var upperArm = Path()
        // Left edge of arm
        upperArm.move(to: CGPoint(x: size * 0.25, y: size * 0.85))
        upperArm.addCurve(
            to: CGPoint(x: size * 0.20, y: size * 0.45),
            control1: CGPoint(x: size * 0.22, y: size * 0.70),
            control2: CGPoint(x: size * 0.15, y: size * 0.55)
        )
        // Bicep peak
        upperArm.addCurve(
            to: CGPoint(x: size * 0.45, y: size * 0.25),
            control1: CGPoint(x: size * 0.22, y: size * 0.35),
            control2: CGPoint(x: size * 0.32, y: size * 0.22)
        )
        // Forearm going right toward dumbbell
        upperArm.addCurve(
            to: CGPoint(x: size * 0.80, y: size * 0.28),
            control1: CGPoint(x: size * 0.58, y: size * 0.26),
            control2: CGPoint(x: size * 0.70, y: size * 0.24)
        )
        // Fist / hand area
        upperArm.addCurve(
            to: CGPoint(x: size * 0.82, y: size * 0.42),
            control1: CGPoint(x: size * 0.88, y: size * 0.30),
            control2: CGPoint(x: size * 0.88, y: size * 0.38)
        )
        // Bottom of forearm
        upperArm.addCurve(
            to: CGPoint(x: size * 0.50, y: size * 0.42),
            control1: CGPoint(x: size * 0.72, y: size * 0.44),
            control2: CGPoint(x: size * 0.60, y: size * 0.44)
        )
        // Inner elbow / bicep underside
        upperArm.addCurve(
            to: CGPoint(x: size * 0.42, y: size * 0.85),
            control1: CGPoint(x: size * 0.42, y: size * 0.55),
            control2: CGPoint(x: size * 0.40, y: size * 0.70)
        )
        upperArm.closeSubpath()

        // Arm fill with gradient
        let armGradient = Gradient(colors: [
            Color(hex: "E8956E"),
            Color(hex: "D4784E"),
            Color(hex: "C06535"),
        ])
        context.fill(
            upperArm,
            with: .linearGradient(
                armGradient,
                startPoint: CGPoint(x: size * 0.3, y: size * 0.2),
                endPoint: CGPoint(x: size * 0.4, y: size * 0.85)
            )
        )

        // Muscle definition line (bicep separation)
        var muscleLine = Path()
        muscleLine.move(to: CGPoint(x: size * 0.30, y: size * 0.50))
        muscleLine.addCurve(
            to: CGPoint(x: size * 0.42, y: size * 0.32),
            control1: CGPoint(x: size * 0.28, y: size * 0.42),
            control2: CGPoint(x: size * 0.34, y: size * 0.33)
        )
        context.stroke(
            muscleLine,
            with: .color(Color(hex: "A0522D").opacity(0.6)),
            lineWidth: size * 0.012
        )

        // Bicep peak highlight
        var highlight = Path()
        highlight.move(to: CGPoint(x: size * 0.32, y: size * 0.30))
        highlight.addCurve(
            to: CGPoint(x: size * 0.44, y: size * 0.27),
            control1: CGPoint(x: size * 0.35, y: size * 0.25),
            control2: CGPoint(x: size * 0.40, y: size * 0.24)
        )
        context.stroke(
            highlight,
            with: .color(Color.white.opacity(0.25)),
            lineWidth: size * 0.015
        )
    }

    private func drawDumbbell(context: GraphicsContext, size: CGFloat) {
        let dumbbellColor = Color(hex: "8B8B9E")
        let plateColor = Color(hex: "6C5CE7")
        let plateDark = Color(hex: "5A4BD6")

        let handleY = size * 0.32
        let handleWidth = size * 0.04

        // Handle (vertical bar in the hand)
        let handleRect = CGRect(
            x: size * 0.74,
            y: handleY - size * 0.15,
            width: handleWidth,
            height: size * 0.30
        )
        context.fill(
            Path(roundedRect: handleRect, cornerRadius: size * 0.01),
            with: .color(dumbbellColor)
        )

        // Top plate
        let topPlateRect = CGRect(
            x: size * 0.71,
            y: handleY - size * 0.20,
            width: size * 0.10,
            height: size * 0.06
        )
        context.fill(
            Path(roundedRect: topPlateRect, cornerRadius: size * 0.015),
            with: .color(plateColor)
        )
        // Top plate inner highlight
        let topInner = CGRect(
            x: size * 0.72,
            y: handleY - size * 0.19,
            width: size * 0.08,
            height: size * 0.04
        )
        context.fill(
            Path(roundedRect: topInner, cornerRadius: size * 0.01),
            with: .color(plateDark)
        )

        // Bottom plate
        let bottomPlateRect = CGRect(
            x: size * 0.71,
            y: handleY + size * 0.14,
            width: size * 0.10,
            height: size * 0.06
        )
        context.fill(
            Path(roundedRect: bottomPlateRect, cornerRadius: size * 0.015),
            with: .color(plateColor)
        )
        let bottomInner = CGRect(
            x: size * 0.72,
            y: handleY + size * 0.15,
            width: size * 0.08,
            height: size * 0.04
        )
        context.fill(
            Path(roundedRect: bottomInner, cornerRadius: size * 0.01),
            with: .color(plateDark)
        )

        // Metallic sheen on handle
        var handleSheen = Path()
        handleSheen.move(to: CGPoint(x: size * 0.755, y: handleY - size * 0.12))
        handleSheen.addLine(to: CGPoint(x: size * 0.760, y: handleY - size * 0.12))
        handleSheen.addLine(to: CGPoint(x: size * 0.760, y: handleY + size * 0.12))
        handleSheen.addLine(to: CGPoint(x: size * 0.755, y: handleY + size * 0.12))
        handleSheen.closeSubpath()
        context.fill(handleSheen, with: .color(Color.white.opacity(0.2)))
    }
}

#Preview {
    AppIconView(size: 512)
        .background(Color.black)
}
