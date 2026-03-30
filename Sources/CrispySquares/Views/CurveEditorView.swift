import SwiftUI

struct CurveEditorView: NSViewRepresentable {
    @Binding var controlPoints: [GammaCurve.ControlPoint]

    func makeNSView(context: Context) -> CurveEditorNSView {
        let view = CurveEditorNSView()
        view.delegate = context.coordinator
        view.controlPoints = controlPoints
        return view
    }

    func updateNSView(_ nsView: CurveEditorNSView, context: Context) {
        nsView.controlPoints = controlPoints
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, CurveEditorDelegate {
        let parent: CurveEditorView
        init(_ parent: CurveEditorView) { self.parent = parent }
        func curveEditorDidUpdatePoints(_ editor: CurveEditorNSView, points: [GammaCurve.ControlPoint]) {
            parent.controlPoints = points
        }
    }
}
