import SwiftUI
import Combine

struct MomentDetailView: View {
    let moment: SimpleMoment
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Hero section with large progress ring
                heroSection
                
                // Main countdown display
                countdownSection
                
                // Date and time info
                dateInfoSection
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .containerBackground(
            LinearGradient(
                colors: [
                    moment.accentColor.opacity(0.25),
                    moment.accentColor.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            for: .navigation
        )
    }
    
    private var heroSection: some View {
        ZStack {
            // Outer glow effect
            Circle()
                .fill(moment.accentColor.opacity(0.15))
                .frame(width: 130, height: 130)
                .blur(radius: 15)
            
            // Background ring
            Circle()
                .stroke(moment.accentColor.opacity(0.2), lineWidth: 10)
                .frame(width: 110, height: 110)
            
            // Progress ring - updates with currentTime
            Circle()
                .trim(from: 0, to: moment.progress)
                .stroke(
                    AngularGradient(
                        colors: [moment.accentColor, moment.accentColor.opacity(0.6)],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 110, height: 110)
                .rotationEffect(.degrees(-90))
                .id(currentTime) // Force refresh on timer tick
            
            // Inner circle with icon
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 75, height: 75)
            
            Image(systemName: moment.symbolName)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(moment.accentColor)
                .symbolRenderingMode(.hierarchical)
        }
    }
    
    private var countdownSection: some View {
        VStack(spacing: 8) {
            Text(moment.title)
                .font(.system(size: 16, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(.primary)
            
            if moment.isPast {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                    Text("Completed")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundStyle(.green)
                .padding(.top, 4)
            } else {
                // Large native countdown
                Text(timerInterval: Date()...moment.targetDate, countsDown: true, showsHours: true)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(moment.accentColor)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                
                Text("REMAINING")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1.5)
            }
        }
    }
    
    private var dateInfoSection: some View {
        VStack(spacing: 8) {
            Divider()
                .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                // Date
                VStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundStyle(moment.accentColor)
                    
                    Text(moment.targetDate, style: .date)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                
                // Divider
                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 1, height: 30)
                
                // Time
                VStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundStyle(moment.accentColor)
                    
                    Text(moment.targetDate, style: .time)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
        }
    }
}

#Preview {
    MomentDetailView(moment: SimpleMoment(
        id: "preview",
        title: "Birthday Party",
        targetDate: Date().addingTimeInterval(3600 * 24),
        createdDate: Date().addingTimeInterval(-86400 * 3),
        accentColorHex: "#FF2D55",
        symbolName: "party.popper.fill"
    ))
}
