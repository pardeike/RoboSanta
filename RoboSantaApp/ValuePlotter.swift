// ValuePlotter.swift
// A scrolling graph that plots servo values over time.

import SwiftUI
import Combine

/// Colors for each servo value
enum ServoColor {
    static let body = Color.red
    static let head = Color.gray
    static let leftArm = Color.blue
    static let rightArm = Color.yellow
    
    static let bodyBackground = Color.red.opacity(0.3)
    static let headBackground = Color.gray.opacity(0.3)
    static let leftArmBackground = Color.blue.opacity(0.3)
    static let rightArmBackground = Color.yellow.opacity(0.3)
}

/// A single data point with all four servo values
struct ServoDataPoint: Identifiable {
    let id = UUID()
    let bodyAngle: Double      // -105...105 degrees
    let headAngle: Double      // -30...30 degrees
    let leftHand: Double       // 0...1
    let rightHand: Double      // 0...1
}

/// Observable class that maintains a rolling buffer of servo data
@MainActor
final class ServoDataBuffer: ObservableObject {
    @Published private(set) var dataPoints: [ServoDataPoint] = []
    
    /// Maximum number of data points to keep
    let maxPoints: Int
    
    init(maxPoints: Int = 200) {
        self.maxPoints = maxPoints
    }
    
    func addDataPoint(pose: StateMachine.FigurinePose) {
        let point = ServoDataPoint(
            bodyAngle: pose.bodyAngle,
            headAngle: pose.headAngle,
            leftHand: pose.leftHand,
            rightHand: pose.rightHand
        )
        dataPoints.append(point)
        if dataPoints.count > maxPoints {
            dataPoints.removeFirst(dataPoints.count - maxPoints)
        }
    }
    
    func clear() {
        dataPoints.removeAll()
    }
}

/// A view that plots the servo values as a scrolling graph
struct ValuePlotter: View {
    @ObservedObject var buffer: ServoDataBuffer
    
    // Value ranges for normalization
    private let bodyRange: ClosedRange<Double> = -105...105
    private let headRange: ClosedRange<Double> = -30...30
    private let handRange: ClosedRange<Double> = 0...1
    /// Padding around the graph content
    private let graphPadding: CGFloat = 4
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let points = buffer.dataPoints
                
                guard points.count > 1 else { return }
                
                let pointSpacing = size.width / CGFloat(buffer.maxPoints - 1)
                let visiblePoints = Array(points.suffix(buffer.maxPoints))
                
                // Draw each servo line
                drawLine(context: context, points: visiblePoints, size: size, pointSpacing: pointSpacing,
                        valueExtractor: { normalize($0.bodyAngle, in: bodyRange) },
                        color: ServoColor.body, lineWidth: 2)
                
                drawLine(context: context, points: visiblePoints, size: size, pointSpacing: pointSpacing,
                        valueExtractor: { normalize($0.headAngle, in: headRange) },
                        color: ServoColor.head, lineWidth: 2)
                
                drawLine(context: context, points: visiblePoints, size: size, pointSpacing: pointSpacing,
                        valueExtractor: { normalize($0.leftHand, in: handRange) },
                        color: ServoColor.leftArm, lineWidth: 2)
                
                drawLine(context: context, points: visiblePoints, size: size, pointSpacing: pointSpacing,
                        valueExtractor: { normalize($0.rightHand, in: handRange) },
                        color: ServoColor.rightArm, lineWidth: 2)
            }
        }
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
    
    private func normalize(_ value: Double, in range: ClosedRange<Double>) -> Double {
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        return (clamped - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
    
    private func drawLine(context: GraphicsContext, points: [ServoDataPoint], size: CGSize,
                         pointSpacing: CGFloat, valueExtractor: (ServoDataPoint) -> Double,
                         color: Color, lineWidth: CGFloat) {
        guard points.count > 1 else { return }
        
        var path = Path()
        let drawHeight = size.height - graphPadding * 2
        
        for (index, point) in points.enumerated() {
            let x = CGFloat(index) * pointSpacing
            let normalizedValue = valueExtractor(point)
            // Invert Y because screen coordinates have origin at top
            let y = graphPadding + drawHeight * (1 - normalizedValue)
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        context.stroke(path, with: .color(color), lineWidth: lineWidth)
    }
}

// MARK: - Preview

struct ValuePlotter_Previews: PreviewProvider {
    static var previews: some View {
        let buffer = ServoDataBuffer(maxPoints: 100)
        // Add some sample data
        for i in 0..<100 {
            let t = Double(i) / 50.0 * .pi
            let pose = StateMachine.FigurinePose(
                bodyAngle: sin(t) * 50,
                headAngle: cos(t * 2) * 20,
                leftHand: (sin(t * 3) + 1) / 2,
                rightHand: (cos(t * 1.5) + 1) / 2
            )
            buffer.addDataPoint(pose: pose)
        }
        return ValuePlotter(buffer: buffer)
            .frame(width: 300, height: 150)
            .padding()
    }
}
