import SwiftUI

struct SimpleGraph: View {
    let data: [Double]
    let title: String
    let color: Color
    let maxValue: Double = 100

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)

            if data.isEmpty {
                Text("No data available")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .frame(height: 60)
            } else {
                ZStack {
                    // Background grid
                    VStack(spacing: 0) {
                        ForEach(0..<5, id: \.self) { _ in
                            Divider()
                                .opacity(0.2)
                            Spacer()
                        }
                        Divider()
                            .opacity(0.2)
                    }

                    // Graph line
                    Canvas { context, size in
                        let width = size.width
                        let height = size.height
                        let step = width / Double(max(data.count - 1, 1))

                        var path = Path()
                        for (index, value) in data.enumerated() {
                            let x = Double(index) * step
                            let y = height * (1 - min(value / maxValue, 1))

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }

                        context.stroke(
                            path,
                            with: .color(color),
                            lineWidth: 1.5
                        )

                        // Fill under curve
                        path.addLine(to: CGPoint(x: width, y: height))
                        path.addLine(to: CGPoint(x: 0, y: height))
                        path.closeSubpath()

                        context.fill(
                            path,
                            with: .color(color.opacity(0.1))
                        )
                    }
                    .frame(height: 60)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(6)
    }
}
