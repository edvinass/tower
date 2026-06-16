import SwiftUI

struct WindMeterView: View {
    let strength: Double
    let direction: CGFloat
    let gustWarning: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: direction >= 0 ? "wind" : "wind")
                .font(.title3)
                .foregroundStyle(gustWarning ? .orange : .white)
                .rotationEffect(.degrees(direction >= 0 ? 0 : 180))
                .symbolEffect(.pulse, isActive: gustWarning)

            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: index))
                        .frame(width: 6, height: CGFloat(8 + index * 3))
                }
            }

            if gustWarning {
                Text("GUST!")
                    .font(.caption2.bold())
                    .foregroundStyle(.orange)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.25), value: gustWarning)
    }

    private func barColor(for index: Int) -> Color {
        let threshold = Double(index + 1) / 5.0
        if strength >= threshold {
            return gustWarning ? .orange : .white.opacity(0.9)
        }
        return .white.opacity(0.25)
    }
}
