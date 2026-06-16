import SwiftUI

struct BlockQueueView: View {
    let blocks: [BlockSpec]
    let queueBaseIndex: Int
    let selectedOffset: Int
    let onSelect: (Int) -> Void
    var onDragChanged: ((CGPoint) -> Void)?
    var onDragEnded: ((CGPoint) -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, spec in
                queueItem(index: index, spec: spec)
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

    private func queueItem(index: Int, spec: BlockSpec) -> some View {
        let isSelected = index == selectedOffset
        return BlockPreview(spec: spec)
            .frame(width: 64, height: 64)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.35) : Color.black.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .id("\(queueBaseIndex)-\(index)-\(spec.token)")
            .gesture(queueDragGesture(index: index, isSelected: isSelected))
    }

    private func queueDragGesture(index: Int, isSelected: Bool) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                let distance = hypot(value.translation.width, value.translation.height)
                guard distance > 3 else { return }
                if !isSelected {
                    onSelect(index)
                }
                onDragChanged?(value.location)
            }
            .onEnded { value in
                let distance = hypot(value.translation.width, value.translation.height)
                if distance <= 3 {
                    onSelect(index)
                    return
                }
                onDragEnded?(value.location)
            }
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
