import ActivityKit
import WidgetKit
import SwiftUI

// Real Moments attributes for countdown
struct MomentsActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var timeRemaining: TimeInterval
        var progress: Double
    }
    
    var momentId: String
    var title: String
    var targetDate: Date
    var symbolName: String
    var accentColorHex: String
    var showEndTime: Bool
}


struct MomentsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MomentsActivityAttributes.self) { context in
            // Lock Screen presentation
            lockScreenView(context: context)
                .activityBackgroundTint(Color(hex: context.attributes.accentColorHex)?.opacity(0.1))
                .activitySystemActionForegroundColor(Color(hex: context.attributes.accentColorHex) ?? .blue)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded presentation
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.attributes.symbolName)
                        .font(.title2)
                        .foregroundStyle(Color(hex: context.attributes.accentColorHex) ?? .blue)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formattedTime(context.state.timeRemaining))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(context.attributes.title)
                            .font(.headline)
                        
                        if context.attributes.showEndTime {
                            Text(context.attributes.targetDate, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: context.attributes.accentColorHex)?.opacity(0.2) ?? .blue.opacity(0.2))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: context.attributes.accentColorHex) ?? .blue)
                                .frame(width: geometry.size.width * context.state.progress)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal)
                }
            } compactLeading: {
                Image(systemName: context.attributes.symbolName)
                    .font(.caption)
                    .foregroundStyle(Color(hex: context.attributes.accentColorHex) ?? .blue)
            } compactTrailing: {
                Text(compactTime(context.state.timeRemaining))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: context.attributes.symbolName)
                    .font(.caption2)
            }
            .keylineTint(Color(hex: context.attributes.accentColorHex))
        }
    }
    
    // MARK: - Lock Screen View
    
    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<MomentsActivityAttributes>) -> some View {
        HStack(spacing: 16) {
            // Progress ring with icon
            ZStack {
                Circle()
                    .stroke(
                        Color(hex: context.attributes.accentColorHex)?.opacity(0.2) ?? .blue.opacity(0.2),
                        lineWidth: 6
                    )
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: context.state.progress)
                    .stroke(
                        Color(hex: context.attributes.accentColorHex) ?? .blue,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: context.attributes.symbolName)
                    .font(.title3)
                    .foregroundStyle(Color(hex: context.attributes.accentColorHex) ?? .blue)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.title)
                    .font(.headline)
                
                Text(detailedTime(context.state.timeRemaining))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color(hex: context.attributes.accentColorHex) ?? .blue)
                
                if context.attributes.showEndTime {
                    HStack(spacing: 4) {
                        Text("Until")
                        Text(context.attributes.targetDate, style: .time)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Time Formatting Helpers
    
    private func formattedTime(_ interval: TimeInterval) -> String {
        let seconds = Int(interval)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        
        if days > 0 {
            return "\(days)d"
        } else if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
    
    private func compactTime(_ interval: TimeInterval) -> String {
        let seconds = Int(interval)
        let minutes = seconds / 60
        let hours = minutes / 60
        
        if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
    
    private func detailedTime(_ interval: TimeInterval) -> String {
        let seconds = Int(interval)
        let minutes = (seconds / 60) % 60
        let hours = (seconds / 3600) % 24
        let days = seconds / 86400
        
        if days > 0 {
            return String(format: "%dd %02d:%02d", days, hours, minutes)
        } else {
            let secs = seconds % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        }
    }
}

// Color extension for hex support
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


#Preview("Live Activity", as: .content, using: MomentsActivityAttributes(
    momentId: "preview",
    title: "Birthday Party",
    targetDate: Date().addingTimeInterval(3600 * 2),
    symbolName: "party.popper.fill",
    accentColorHex: "#FF2D55",
    showEndTime: true
)) {
    MomentsLiveActivity()
} contentStates: {
    MomentsActivityAttributes.ContentState(timeRemaining: 7200, progress: 0.3)
    MomentsActivityAttributes.ContentState(timeRemaining: 3600, progress: 0.6)
    MomentsActivityAttributes.ContentState(timeRemaining: 600, progress: 0.9)
}
