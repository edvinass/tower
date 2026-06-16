import SwiftUI

struct HeightMeterView: View {
    let current: Double
    let target: Double
    let holdProgress: Double

    private var fillRatio: CGFloat {
        guard target > 0 else { return 0 }
        return CGFloat(min(current / target, 1.1))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )

                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: holdProgress > 0
                                ? [Color.green, Color.mint]
                                : [Color.orange, Color.yellow],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: geo.size.height * fillRatio)
                    .padding(4)
                    .animation(.easeOut(duration: 0.2), value: fillRatio)

                if target > 0 {
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(height: 2)
                        .padding(.horizontal, 6)
                        .offset(y: -geo.size.height * CGFloat(min(target / max(current, target), 1)) + 4)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if holdProgress > 0 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                    .offset(x: 4, y: -4)
            }
        }
        .accessibilityLabel("Height \(Int(current)) of \(Int(target))")
    }
}
