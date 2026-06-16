import CoreGraphics

enum BlockShape: String, Codable, CaseIterable, Identifiable {
    case rectangle
    case square
    case triangle
    case lShape
    case tShape
    case circle
    case plank
    case arc

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rectangle: return "Rectangle"
        case .square: return "Square"
        case .triangle: return "Triangle"
        case .lShape: return "L-Shape"
        case .tShape: return "T-Shape"
        case .circle: return "Circle"
        case .plank: return "Plank"
        case .arc: return "Arc"
        }
    }

    var unitSize: CGSize {
        switch self {
        case .rectangle: return CGSize(width: 80, height: 40)
        case .square: return CGSize(width: 50, height: 50)
        case .triangle: return CGSize(width: 60, height: 50)
        case .lShape: return CGSize(width: 70, height: 70)
        case .tShape: return CGSize(width: 80, height: 60)
        case .circle: return CGSize(width: 44, height: 44)
        case .plank: return CGSize(width: 100, height: 18)
        case .arc: return CGSize(width: 60, height: 30)
        }
    }

    func path(size: CGSize, rotationSteps: Int = 0) -> CGPath {
        let base = basePath(size: size)
        guard rotationSteps % 4 != 0 else { return base }
        return rotate(path: base, steps: rotationSteps % 4, size: size)
    }

    func physicsPoints(size: CGSize, rotationSteps: Int = 0) -> [CGPoint] {
        if self == .circle {
            return []
        }
        let path = self.path(size: size, rotationSteps: rotationSteps)
        return path.points
    }

    private func basePath(size: CGSize) -> CGPath {
        let w = size.width
        let h = size.height
        let path = CGMutablePath()

        switch self {
        case .rectangle, .square:
            path.addRect(CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
        case .triangle:
            path.move(to: CGPoint(x: 0, y: h / 2))
            path.addLine(to: CGPoint(x: -w / 2, y: -h / 2))
            path.addLine(to: CGPoint(x: w / 2, y: -h / 2))
            path.closeSubpath()
        case .lShape:
            let t: CGFloat = w / 3
            path.addRect(CGRect(x: -w / 2, y: -h / 2, width: t, height: h))
            path.addRect(CGRect(x: -w / 2, y: -h / 2, width: w, height: t))
        case .tShape:
            let t: CGFloat = h / 3
            path.addRect(CGRect(x: -w / 2, y: h / 2 - t, width: w, height: t))
            path.addRect(CGRect(x: -t / 2, y: -h / 2, width: t, height: h))
        case .circle:
            path.addEllipse(in: CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
        case .plank:
            path.addRect(CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
        case .arc:
            path.addArc(center: CGPoint(x: 0, y: -h / 2), radius: w / 2, startAngle: 0, endAngle: .pi, clockwise: false)
            path.addLine(to: CGPoint(x: w / 2, y: -h / 2))
            path.addLine(to: CGPoint(x: -w / 2, y: -h / 2))
            path.closeSubpath()
        }
        return path
    }

    private func rotate(path: CGPath, steps: Int, size: CGSize) -> CGPath {
        var transform = CGAffineTransform.identity
        let angle = CGFloat(steps) * .pi / 2
        transform = transform.translatedBy(x: 0, y: 0)
        transform = transform.rotated(by: angle)
        return path.copy(using: &transform) ?? path
    }
}

private extension CGPath {
    var points: [CGPoint] {
        var result: [CGPoint] = []
        applyWithBlock { element in
            let pointsPointer = element.pointee.points
            switch element.pointee.type {
            case .moveToPoint, .addLineToPoint:
                result.append(pointsPointer[0])
            case .addQuadCurveToPoint:
                result.append(pointsPointer[1])
            case .addCurveToPoint:
                result.append(pointsPointer[2])
            default:
                break
            }
        }
        return simplifyConvexHull(result)
    }
}

private func simplifyConvexHull(_ points: [CGPoint]) -> [CGPoint] {
    guard points.count > 2 else { return points }
    let sorted = points.sorted { $0.x == $1.x ? $0.y < $1.y : $0.x < $1.x }
    func cross(_ o: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
        (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
    }
    var lower: [CGPoint] = []
    for p in sorted {
        while lower.count >= 2 && cross(lower[lower.count - 2], lower[lower.count - 1], p) <= 0 {
            lower.removeLast()
        }
        lower.append(p)
    }
    var upper: [CGPoint] = []
    for p in sorted.reversed() {
        while upper.count >= 2 && cross(upper[upper.count - 2], upper[upper.count - 1], p) <= 0 {
            upper.removeLast()
        }
        upper.append(p)
    }
    lower.removeLast()
    upper.removeLast()
    return lower + upper
}
