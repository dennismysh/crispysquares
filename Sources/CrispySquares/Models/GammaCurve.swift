import Foundation

struct GammaCurve: Codable, Equatable {

    struct ControlPoint: Codable, Equatable {
        let x: Float
        let y: Float
    }

    enum CurveType: Codable, Equatable {
        case parametric(gamma: Float, blackPoint: Float, whitePoint: Float, contrastBoost: Float)
        case controlPoints([ControlPoint])
    }

    let curveType: CurveType

    // MARK: - Factories

    static func parametric(
        gamma: Float,
        blackPoint: Float = 0.0,
        whitePoint: Float = 1.0,
        contrastBoost: Float = 0.0
    ) -> GammaCurve {
        GammaCurve(curveType: .parametric(
            gamma: gamma, blackPoint: blackPoint,
            whitePoint: whitePoint, contrastBoost: contrastBoost
        ))
    }

    static func controlPoints(_ points: [ControlPoint]) -> GammaCurve {
        GammaCurve(curveType: .controlPoints(points))
    }

    // MARK: - Table Generation

    func generateTable(size: Int) -> [Float] {
        (0..<size).map { i in
            let x = Float(i) / Float(size - 1)
            let y = evaluate(at: x)
            return min(max(y, 0.0), 1.0)
        }
    }

    func evaluate(at x: Float) -> Float {
        switch curveType {
        case let .parametric(gamma, blackPoint, whitePoint, contrastBoost):
            return evaluateParametric(x: x, gamma: gamma, blackPoint: blackPoint,
                                      whitePoint: whitePoint, contrastBoost: contrastBoost)
        case let .controlPoints(points):
            return evaluateControlPoints(x: x, points: points)
        }
    }

    // MARK: - Parametric

    private func evaluateParametric(
        x: Float, gamma: Float, blackPoint: Float, whitePoint: Float, contrastBoost: Float
    ) -> Float {
        var y = powf(x, gamma)
        if contrastBoost > 0 {
            y = applySCurve(y, strength: contrastBoost)
        }
        return blackPoint + y * (whitePoint - blackPoint)
    }

    private func applySCurve(_ x: Float, strength: Float) -> Float {
        let k = 1.0 + strength * 4.0
        if x < 0.5 {
            return 0.5 * powf(2.0 * x, k)
        } else {
            return 1.0 - 0.5 * powf(2.0 * (1.0 - x), k)
        }
    }

    // MARK: - Control Points (Monotone Cubic Interpolation)

    private func evaluateControlPoints(x: Float, points: [ControlPoint]) -> Float {
        guard points.count >= 2 else { return x }
        let sorted = points.sorted { $0.x < $1.x }
        if x <= sorted.first!.x { return sorted.first!.y }
        if x >= sorted.last!.x { return sorted.last!.y }

        var segIndex = 0
        for i in 0..<(sorted.count - 1) {
            if x >= sorted[i].x && x <= sorted[i + 1].x {
                segIndex = i
                break
            }
        }

        let p0 = sorted[segIndex]
        let p1 = sorted[segIndex + 1]

        if sorted.count == 2 {
            let t = (x - p0.x) / (p1.x - p0.x)
            return p0.y + t * (p1.y - p0.y)
        }

        // Monotone cubic Hermite interpolation (Fritsch-Carlson)
        let t = (x - p0.x) / (p1.x - p0.x)
        let m0 = tangent(at: segIndex, points: sorted)
        let m1 = tangent(at: segIndex + 1, points: sorted)
        let dx = p1.x - p0.x
        let t2 = t * t
        let t3 = t2 * t

        let h00 = 2 * t3 - 3 * t2 + 1
        let h10 = t3 - 2 * t2 + t
        let h01 = -2 * t3 + 3 * t2
        let h11 = t3 - t2

        return h00 * p0.y + h10 * dx * m0 + h01 * p1.y + h11 * dx * m1
    }

    private func tangent(at index: Int, points: [ControlPoint]) -> Float {
        if index == 0 {
            return (points[1].y - points[0].y) / (points[1].x - points[0].x)
        }
        if index == points.count - 1 {
            let last = points.count - 1
            return (points[last].y - points[last - 1].y) / (points[last].x - points[last - 1].x)
        }
        let d0 = (points[index].y - points[index - 1].y) / (points[index].x - points[index - 1].x)
        let d1 = (points[index + 1].y - points[index].y) / (points[index + 1].x - points[index].x)
        return (d0 + d1) / 2.0
    }
}
