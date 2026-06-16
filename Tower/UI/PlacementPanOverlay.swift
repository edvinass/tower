import UIKit
import SwiftUI

/// UIKit pan recognizer survives SwiftUI re-renders better than SwiftUI DragGesture.
struct PlacementPanOverlay: UIViewRepresentable {
    let isEnabled: Bool
    let onPan: (CGPoint, UIGestureRecognizer.State) -> Void

    func makeUIView(context: Context) -> PlacementPanUIView {
        let view = PlacementPanUIView()
        view.onPan = onPan
        return view
    }

    func updateUIView(_ uiView: PlacementPanUIView, context: Context) {
        uiView.isUserInteractionEnabled = isEnabled
        uiView.onPan = onPan
    }
}

final class PlacementPanUIView: UIView {
    var onPan: ((CGPoint, UIGestureRecognizer.State) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.minimumNumberOfTouches = 1
        pan.cancelsTouchesInView = false
        addGestureRecognizer(pan)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let window = window else { return }
        let point = gesture.location(in: window)
        onPan?(point, gesture.state)
    }
}
