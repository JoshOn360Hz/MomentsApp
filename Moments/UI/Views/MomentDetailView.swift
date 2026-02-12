import SwiftUI
import Combine

struct MomentDetailView: View {
    @Bindable var moment: Moment
    @State private var showingEditor = false
    @State private var currentTime = Date()
    @Environment(\.dismiss) private var dismiss
    
    // Timer to refresh countdown
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    moment.accentColor.opacity(0.25),
                    moment.accentColor.opacity(0.05),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Spacer for nav bar
                    Color.clear.frame(height: 20)
                    
                    // Mega countdown
                    countdownSection
                    
                    // Details grid
                    detailsGrid
                    
                    // Status badges
                    statusSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image(systemName: moment.symbolName)
                        .foregroundStyle(moment.accentColor)
                        .font(.headline)
                    
                    Text(moment.title)
                        .font(.headline)
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditor = true
                } label: {
                    Text("Edit")
                        .fontWeight(.semibold)
                        .foregroundStyle(moment.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            MomentEditorView(existingMoment: moment)
        }
    }
    
    
    private var countdownSection: some View {
        VStack(spacing: 24) {
            // Large icon with glow
            ZStack {
                // Outer glow
                Circle()
                    .fill(moment.accentColor.opacity(0.2))
                    .frame(width: 130, height: 130)
                    .blur(radius: 20)
                
                // Icon background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 110, height: 110)
                    .overlay {
                        Circle()
                            .strokeBorder(moment.accentColor.opacity(0.3), lineWidth: 1)
                    }
                
                // Icon
                Image(systemName: moment.symbolName)
                    .font(.system(size: 56))
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
            
            // Main countdown
            VStack(spacing: 12) {
                Text(TimeEngine.detailedCountdown(for: moment))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
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
                    .id(currentTime)
                
                Text(TimeEngine.formattedTimeRemaining(for: moment))
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .id(currentTime)
            }
            
            // Sleek progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .frame(height: 8)
                    
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
                        .frame(width: geometry.size.width * moment.progress, height: 8)
                        .shadow(color: moment.accentColor.opacity(0.4), radius: 4, y: 2)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 12)
    }
    
    
    private var detailsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], alignment: .leading, spacing: 12) {
            DetailCard(
                icon: "calendar",
                label: "Target",
                value: TimeEngine.formattedTargetDate(moment.targetDate),
                color: moment.accentColor
            )
            
            DetailCard(
                icon: "clock",
                label: "Remaining",
                value: TimeEngine.relativeDate(moment.targetDate),
                color: moment.accentColor
            )
            
            DetailCard(
                icon: "chart.line.uptrend.xyaxis",
                label: "Progress",
                value: "\(Int(moment.progress * 100))%",
                color: moment.accentColor
            )
            
            DetailCard(
                icon: "hourglass",
                label: "Created",
                value: TimeEngine.formattedTargetDate(moment.createdDate),
                color: moment.accentColor
            )
        }
    }
    
    
    private var statusSection: some View {
        VStack(spacing: 12) {
            // Live Activity
            if moment.shouldShowLiveActivity {
                StatusBadge(
                    icon: "livephoto",
                    title: "Live Activity",
                    subtitle: "Shown on Lock Screen",
                    badgeColor: .green
                )
            }
            
            // Notifications
            if moment.notifyTwentyFourHours || moment.notifyOneHour || moment.notifyTenMinutes {
                StatusBadge(
                    icon: "bell.fill",
                    title: "Reminders",
                    subtitle: notificationSummary,
                    badgeColor: .orange
                )
            }
        }
    }
    
    private var notificationSummary: String {
        var times: [String] = []
        if moment.notifyTwentyFourHours { times.append("24h") }
        if moment.notifyOneHour { times.append("1h") }
        if moment.notifyTenMinutes { times.append("10m") }
        return times.isEmpty ? "None" : times.joined(separator: ", ") + " before"
    }
}


struct DetailCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                
                Text(value)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(color.opacity(0.1), lineWidth: 1)
                }
        }
    }
}


struct StatusBadge: View {
    let icon: String
    let title: String
    let subtitle: String
    let badgeColor: Color
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(badgeColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(badgeColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(badgeColor)
                .font(.title3)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(badgeColor.opacity(0.1), lineWidth: 1)
                }
        }
    }
}

#Preview {
    NavigationStack {
        MomentDetailView(
            moment: Moment(
                title: "Summer Vacation",
                targetDate: Date().addingTimeInterval(86400 * 30),
                accentColorHex: "#FF9500",
                symbolName: "sun.max.fill",
                notifyTwentyFourHours: true,
                notifyOneHour: true
            )
        )
    }
}
