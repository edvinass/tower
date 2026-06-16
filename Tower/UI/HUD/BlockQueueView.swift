import SwiftUI

struct BlockQueueView: View {
    let blocks: [BlockSpec]
    let selectedOffset: Int
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, spec in
                Button {
                    onSelect(index)
                } label: {
                    BlockPreview(spec: spec)
                        .frame(width: 64, height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(index == selectedOffset ? Color.white.opacity(0.35) : Color.black.opacity(0.2))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(index == selectedOffset ? Color.white : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }

            if blocks.isEmpty {
                Text("No blocks left")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct BlockPreview: View {
    let spec: BlockSpec

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 8, dy: 8)
            let shapeSize = spec.shape.unitSize
            let scale = min(rect.width / shapeSize.width, rect.height / shapeSize.height) * 0.85
            let path = spec.shape.path(size: CGSize(width: shapeSize.width * scale, height: shapeSize.height * scale))
            var transform = CGAffineTransform(translationX: size.width / 2, y: size.height / 2)
            if let transformed = path.copy(using: &transform) {
                context.fill(Path(transformed), with: .color(spec.material.swiftUIColor))
                context.stroke(Path(transformed), with: .color(.white.opacity(0.4)), lineWidth: 1)
            }
        }
    }
}
