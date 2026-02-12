import SwiftUI

struct MomentTileView: View {
    let moment: Moment
    let style: TileStyle
    
    enum TileStyle {
        case compact    // For widgets and lists
        case detailed   // For full app display
        case widget     // Optimized for widget contexts
    }
    
    var body: some View {
        switch style {
        case .compact:
            compactTile
        case .detailed:
            detailedTile
        case .widget:
            widgetTile
        }
    }
    
    
    private var compactTile: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Icon
                ZStack {
                    Circle()
                        .fill(moment.accentColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: moment.symbolName)
                        .font(.system(size: 26))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    moment.accentColor,
                                    moment.accentColor.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.trailing, 16)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(moment.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    // Countdown - large and prominent
                    Text(TimeEngine.detailedCountdown(for: moment))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    moment.accentColor,
                                    moment.accentColor.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .monospacedDigit()
                    
                    // Subtitle with relative time
                    HStack(spacing: 6) {
                        Circle()
                            .fill(moment.accentColor.opacity(0.6))
                            .frame(width: 4, height: 4)
                        
                        Text(TimeEngine.relativeDate(moment.targetDate))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .padding(.bottom, 12)
            
            // Horizontal progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(moment.accentColor.opacity(0.15))
                        .frame(height: 6)
                    
                    // Progress fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    moment.accentColor,
                                    moment.accentColor.opacity(0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * moment.progress, height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background {
            ZStack {
                // Gradient background
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                moment.accentColor.opacity(0.08),
                                moment.accentColor.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Material overlay
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        moment.accentColor.opacity(0.3),
                                        moment.accentColor.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
            .shadow(color: moment.accentColor.opacity(0.15), radius: 12, y: 6)
        }
    }
    
    
    private var detailedTile: some View {
        VStack(spacing: 20) {
            // Header with icon and title
            HStack(spacing: 12) {
                Image(systemName: moment.symbolName)
                    .font(.title2)
                    .foregroundStyle(moment.accentColor)
                    .symbolEffect(.pulse, options: .repeating)
                
                Text(moment.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            // Large progress ring
            ZStack {
                ProgressRingView(
                    progress: moment.progress,
                    color: moment.accentColor,
                    lineWidth: 14,
                    size: 200
                )
                
                VStack(spacing: 12) {
                    Text(TimeEngine.detailedCountdown(for: moment))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(moment.accentColor)
                    
                    Text(TimeEngine.formattedTimeRemaining(for: moment))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 20)
            
            // Target date with icon
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(moment.accentColor)
                
                Text(TimeEngine.formattedTargetDate(moment.targetDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(28)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
                .shadow(color: moment.accentColor.opacity(0.2), radius: 16, y: 8)
        }
    }
    
    
    private var widgetTile: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: moment.symbolName)
                    .font(.caption)
                    .foregroundStyle(moment.accentColor)
                
                Text(moment.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Text(moment.targetDate, style: .timer)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
            
            // Thin progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(moment.accentColor.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(moment.accentColor)
                        .frame(width: geometry.size.width * moment.progress)
                }
            }
            .frame(height: 4)
        }
    }
}

#Preview("Compact") {
    VStack {
        MomentTileView(
            moment: Moment(
                title: "Birthday Party",
                targetDate: Date().addingTimeInterval(86400 * 5),
                accentColorHex: "#FF006E",
                symbolName: "party.popper.fill"
            ),
            style: .compact
        )
        
        MomentTileView(
            moment: Moment(
                title: "Exam",
                targetDate: Date().addingTimeInterval(3600 * 12),
                accentColorHex: "#8338EC",
                symbolName: "pencil.and.list.clipboard"
            ),
            style: .compact
        )
    }
    .padding()
}

#Preview("Detailed") {
    MomentTileView(
        moment: Moment(
            title: "Wedding Day",
            targetDate: Date().addingTimeInterval(86400 * 45),
            accentColorHex: "#FB5607",
            symbolName: "heart.fill"
        ),
        style: .detailed
    )
    .padding()
}

#Preview("Widget") {
    MomentTileView(
        moment: Moment(
            title: "Concert",
            targetDate: Date().addingTimeInterval(3600 * 6),
            accentColorHex: "#3A86FF",
            symbolName: "music.note"
        ),
        style: .widget
    )
    .padding()
    .frame(width: 150, height: 100)
    .background(Color.gray.opacity(0.1))
}
