import AppKit
import CoreGraphics

protocol CurveEditorDelegate: AnyObject {
    func curveEditorDidUpdatePoints(_ editor: CurveEditorNSView, points: [GammaCurve.ControlPoint])
}

final class CurveEditorNSView: NSView {
    weak var delegate: CurveEditorDelegate?

    var controlPoints: [GammaCurve.ControlPoint] = [
        GammaCurve.ControlPoint(x: 0.0, y: 0.0),
        GammaCurve.ControlPoint(x: 1.0, y: 1.0),
    ] {
        didSet { needsDisplay = true }
    }

    private var draggedPointIndex: Int?
    private let pointRadius: CGFloat = 6.0
    private let hitRadius: CGFloat = 12.0

    override var isFlipped: Bool { false }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let inset: CGFloat = 20
        let plotRect = bounds.insetBy(dx: inset, dy: inset)
        drawBackground(context: context, rect: plotRect)
        drawGrid(context: context, rect: plotRect)
        drawReferenceLine(context: context, rect: plotRect)
        drawCurve(context: context, rect: plotRect)
        drawControlPoints(context: context, rect: plotRect)
    }

    private func drawBackground(context: CGContext, rect: CGRect) {
        context.setFillColor(NSColor(white: 0.1, alpha: 1).cgColor)
        context.fill(rect)
    }

    private func drawGrid(context: CGContext, rect: CGRect) {
        context.setStrokeColor(NSColor(white: 0.2, alpha: 1).cgColor)
        context.setLineWidth(0.5)
        for i in 0...4 {
            let frac = CGFloat(i) / 4.0
            let x = rect.minX + frac * rect.width
            let y = rect.minY + frac * rect.height
            context.move(to: CGPoint(x: x, y: rect.minY))
            context.addLine(to: CGPoint(x: x, y: rect.maxY))
            context.strokePath()
            context.move(to: CGPoint(x: rect.minX, y: y))
            context.addLine(to: CGPoint(x: rect.maxX, y: y))
            context.strokePath()
        }
    }

    private func drawReferenceLine(context: CGContext, rect: CGRect) {
        context.setStrokeColor(NSColor(white: 0.35, alpha: 1).cgColor)
        context.setLineWidth(1)
        context.setLineDash(phase: 0, lengths: [4, 4])
        context.move(to: CGPoint(x: rect.minX, y: rect.minY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])
    }

    private func drawCurve(context: CGContext, rect: CGRect) {
        let curve = GammaCurve.controlPoints(controlPoints)
        let steps = 200
        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(2)
        context.beginPath()
        for i in 0...steps {
            let x = Float(i) / Float(steps)
            let y = curve.evaluate(at: x)
            let px = rect.minX + CGFloat(x) * rect.width
            let py = rect.minY + CGFloat(y) * rect.height
            if i == 0 { context.move(to: CGPoint(x: px, y: py)) }
            else { context.addLine(to: CGPoint(x: px, y: py)) }
        }
        context.strokePath()
    }

    private func drawControlPoints(context: CGContext, rect: CGRect) {
        for (index, point) in controlPoints.enumerated() {
            let center = pointToView(point, in: rect)
            let isEndpoint = index == 0 || index == controlPoints.count - 1
            let isDragging = draggedPointIndex == index
            context.setFillColor(
                isDragging ? NSColor.systemIndigo.cgColor : NSColor.white.cgColor
            )
            context.fillEllipse(in: CGRect(
                x: center.x - pointRadius, y: center.y - pointRadius,
                width: pointRadius * 2, height: pointRadius * 2
            ))
            context.setStrokeColor(
                isEndpoint ? NSColor.systemGray.cgColor : NSColor.systemIndigo.cgColor
            )
            context.setLineWidth(2)
            context.strokeEllipse(in: CGRect(
                x: center.x - pointRadius, y: center.y - pointRadius,
                width: pointRadius * 2, height: pointRadius * 2
            ))
        }
    }

    // MARK: - Coordinate Conversion

    private var plotRect: CGRect { bounds.insetBy(dx: 20, dy: 20) }

    private func pointToView(_ point: GammaCurve.ControlPoint, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + CGFloat(point.x) * rect.width,
            y: rect.minY + CGFloat(point.y) * rect.height
        )
    }

    private func viewToPoint(_ viewPoint: CGPoint, in rect: CGRect) -> GammaCurve.ControlPoint {
        let x = Float((viewPoint.x - rect.minX) / rect.width)
        let y = Float((viewPoint.y - rect.minY) / rect.height)
        return GammaCurve.ControlPoint(x: min(max(x, 0), 1), y: min(max(y, 0), 1))
    }

    // MARK: - Mouse Interaction

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        let rect = plotRect
        for (index, point) in controlPoints.enumerated() {
            let center = pointToView(point, in: rect)
            let distance = hypot(location.x - center.x, location.y - center.y)
            if distance <= hitRadius {
                draggedPointIndex = index
                needsDisplay = true
                return
            }
        }
        if event.clickCount == 2 {
            let newPoint = viewToPoint(location, in: rect)
            if newPoint.x > 0.01 && newPoint.x < 0.99 {
                controlPoints.append(newPoint)
                controlPoints.sort { $0.x < $1.x }
                draggedPointIndex = controlPoints.firstIndex(where: { $0.x == newPoint.x && $0.y == newPoint.y })
                delegate?.curveEditorDidUpdatePoints(self, points: controlPoints)
                needsDisplay = true
            }
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let index = draggedPointIndex else { return }
        let location = convert(event.locationInWindow, from: nil)
        let rect = plotRect
        var newPoint = viewToPoint(location, in: rect)
        if index == 0 {
            newPoint = GammaCurve.ControlPoint(x: 0.0, y: newPoint.y)
        } else if index == controlPoints.count - 1 {
            newPoint = GammaCurve.ControlPoint(x: 1.0, y: newPoint.y)
        } else {
            let minX = controlPoints[index - 1].x + 0.01
            let maxX = controlPoints[index + 1].x - 0.01
            newPoint = GammaCurve.ControlPoint(x: min(max(newPoint.x, minX), maxX), y: newPoint.y)
        }
        controlPoints[index] = newPoint
        delegate?.curveEditorDidUpdatePoints(self, points: controlPoints)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        draggedPointIndex = nil
        needsDisplay = true
    }

    override func rightMouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        let rect = plotRect
        for (index, point) in controlPoints.enumerated() {
            let center = pointToView(point, in: rect)
            let distance = hypot(location.x - center.x, location.y - center.y)
            if distance <= hitRadius && index != 0 && index != controlPoints.count - 1 {
                controlPoints.remove(at: index)
                delegate?.curveEditorDidUpdatePoints(self, points: controlPoints)
                needsDisplay = true
                return
            }
        }
    }
}
