import SwiftUI
struct SensorGraphView: View {
    let samples: [MovementSample]; let value: (MovementSample) -> Double; let color: Color
    var body: some View { GeometryReader { geo in
        let values = samples.map(value); let maxValue = max(values.max() ?? 1, 0.01)
        Path { path in for (i, point) in values.enumerated() { let x = geo.size.width * CGFloat(i) / CGFloat(max(values.count - 1, 1)); let y = geo.size.height * (1 - CGFloat(point / maxValue)); i == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y)) } }.stroke(color, lineWidth: 2)
    }.frame(height: 90).background(.quaternary, in: RoundedRectangle(cornerRadius: 8)) }
}
