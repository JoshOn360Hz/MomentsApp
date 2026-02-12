import SwiftUI

struct ProgressRingView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat
    
    init(
        progress: Double,
        color: Color = .blue,
        lineWidth: CGFloat = 8,
        size: CGFloat = 120
    ) {
        self.progress = progress
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    color.opacity(0.2),
                    lineWidth: lineWidth
                )
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 40) {
        ProgressRingView(progress: 0.3, color: .blue)
        ProgressRingView(progress: 0.7, color: .purple, lineWidth: 6, size: 80)
        ProgressRingView(progress: 1.0, color: .green, lineWidth: 12, size: 150)
    }
    .padding()
}
