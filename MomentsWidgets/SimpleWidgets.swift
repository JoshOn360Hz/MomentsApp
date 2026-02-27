import WidgetKit
import SwiftUI
import Foundation

enum AppGroup {
    static let identifier = "group.moments.shareddata"
    
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}

struct SimpleMoment: Codable, Identifiable {
    let id: String
    let title: String
    let targetDate: Date
    let createdDate: Date
    let accentColorHex: String
    let symbolName: String
    
    var accentColor: Color {
        Color(hex: accentColorHex) ?? .blue
    }
    
    var timeRemaining: TimeInterval {
        targetDate.timeIntervalSinceNow
    }
    
    var progress: Double {
        // Use actual creation date for accurate progress
        let totalDuration = targetDate.timeIntervalSince(createdDate)
        let elapsed = Date().timeIntervalSince(createdDate)
        let rawProgress = elapsed / totalDuration
        
        // Use minimum progress to ensure visibility
        let minProgress: Double
        if totalDuration > 86400 { // > 1 day
            minProgress = 0.15
        } else if totalDuration > 3600 { // > 1 hour
            minProgress = 0.10
        } else {
            minProgress = 0.05
        }
        
        return min(max(rawProgress, minProgress), 1.0)
    }
}

// MARK: - Simple Data Provider

struct SimpleMomentsProvider: TimelineProvider {
    typealias Entry = SimpleMomentsEntry
    
    func placeholder(in context: Context) -> SimpleMomentsEntry {
        SimpleMomentsEntry(date: Date(), moments: sampleMoments())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleMomentsEntry) -> Void) {
        let entry = SimpleMomentsEntry(date: Date(), moments: loadMoments())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleMomentsEntry>) -> Void) {
        let moments = loadMoments()
        let now = Date()
        
        // With native Text(timerInterval:) handling countdown displays,
        // we only need to refresh for progress ring updates
        // Timeline updates are now much less frequent since countdown is automatic
        
        var entries: [SimpleMomentsEntry] = []
        
        // Determine update interval based on nearest moment
        // Progress ring needs occasional updates, but not as frequent as manual countdown
        let updateInterval: TimeInterval
        if let firstMoment = moments.first {
            let timeRemaining = firstMoment.timeRemaining
            if timeRemaining < 3600 { // Less than 1 hour
                updateInterval = 300 // Update every 5 minutes for progress ring
            } else if timeRemaining < 86400 { // Less than 24 hours
                updateInterval = 900 // Update every 15 minutes
            } else {
                updateInterval = 3600 // Update hourly for long-term events
            }
        } else {
            updateInterval = 3600 // No moments, update hourly
        }
        
        // Create fewer timeline entries since countdown is handled natively
        for i in 0..<10 {
            let date = Calendar.current.date(byAdding: .second, value: Int(updateInterval * Double(i)), to: now) ?? now
            entries.append(SimpleMomentsEntry(date: date, moments: moments))
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func loadMoments() -> [SimpleMoment] {
        // Try to load from App Group shared data
        guard let sharedDefaults = UserDefaults(suiteName: AppGroup.identifier) else {
            return sampleMoments()
        }
        
        guard let data = sharedDefaults.data(forKey: "SharedMoments") else {
            return sampleMoments()
        }
        
        guard let moments = try? JSONDecoder().decode([SimpleMoment].self, from: data) else {
            return sampleMoments()
        }
        
        // Return only upcoming moments, sorted by date
        let upcomingMoments = moments
            .filter { $0.timeRemaining > 0 }
            .sorted { $0.targetDate < $1.targetDate }
        
        return upcomingMoments
    }
    
    private func sampleMoments() -> [SimpleMoment] {
        [
            SimpleMoment(
                id: "sample-1",
                title: "Sample Birthday",
                targetDate: Date().addingTimeInterval(86400 * 2),
                createdDate: Date().addingTimeInterval(-86400 * 5), // Created 5 days ago
                accentColorHex: "#FF2D55",
                symbolName: "party.popper.fill"
            ),
            SimpleMoment(
                id: "sample-2", 
                title: "Sample Meeting",
                targetDate: Date().addingTimeInterval(3600 * 4),
                createdDate: Date().addingTimeInterval(-3600 * 2), // Created 2 hours ago
                accentColorHex: "#007AFF",
                symbolName: "calendar"
            )
        ]
    }
}

struct SimpleMomentsEntry: TimelineEntry {
    let date: Date
    let moments: [SimpleMoment]
}

// MARK: - Small Widget

struct SmallMomentsWidget: Widget {
    let kind: String = "SmallMomentsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SimpleMomentsProvider()) { entry in
            SmallWidgetView(entry: entry)
                .containerBackground(.regularMaterial, for: .widget)
        }
        .configurationDisplayName("Moments Small")
        .description("Next upcoming moment")
        .supportedFamilies([.systemSmall])
    }
}

struct SmallWidgetView: View {
    var entry: SimpleMomentsEntry
    
    var body: some View {
        if let moment = entry.moments.first {
            VStack(spacing: 8) {
                // Progress circle with icon
                ZStack {
                    Circle()
                        .stroke(moment.accentColor.opacity(0.2), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: moment.progress)
                        .stroke(moment.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: moment.symbolName)
                        .font(.title3)
                        .foregroundStyle(moment.accentColor)
                }
                
                Text(moment.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                // Native countdown - updates automatically without refresh
                Text(timerInterval: Date()...moment.targetDate, countsDown: true)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding()
        } else {
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.plus")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                
                Text("No Moments")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - Medium Widget

struct MediumMomentsWidget: Widget {
    let kind: String = "MediumMomentsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SimpleMomentsProvider()) { entry in
            MediumWidgetView(entry: entry)
                .containerBackground(.regularMaterial, for: .widget)
        }
        .configurationDisplayName("Moments Medium")
        .description("Multiple upcoming moments")
        .supportedFamilies([.systemMedium])
    }
}

struct MediumWidgetView: View {
    var entry: SimpleMomentsEntry
    
    var body: some View {
        if entry.moments.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                
                Text("No Moments")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("Create one in the app")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
        } else {
            HStack(spacing: 16) {
                ForEach(entry.moments.prefix(2)) { moment in
                    VStack(spacing: 8) {
                        // Icon with background
                        ZStack {
                            Circle()
                                .fill(moment.accentColor.opacity(0.15))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: moment.symbolName)
                                .font(.title2)
                                .foregroundStyle(moment.accentColor)
                        }
                        
                        Text(moment.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        // Native countdown - updates automatically without refresh
                        Text(timerInterval: Date()...moment.targetDate, countsDown: true)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                        
                        // Progress bar
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
                    .frame(maxWidth: .infinity)
                }
                
                if entry.moments.count == 1 {
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
    }
}

// MARK: - Circular Lock Screen Widget

struct CircularLockWidget: Widget {
    let kind: String = "CircularLockWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SimpleMomentsProvider()) { entry in
            CircularLockView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Circular Moment")
        .description("Next moment with progress ring")
        .supportedFamilies([.accessoryCircular])
    }
}

struct CircularLockView: View {
    var entry: SimpleMomentsEntry
    
    var body: some View {
        if let moment = entry.moments.first {
            ZStack {
                Circle()
                    .stroke(.tertiary, lineWidth: 2)
                
                Circle()
                    .trim(from: 0, to: moment.progress)
                    .stroke(.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 1) {
                    Image(systemName: moment.symbolName)
                        .font(.system(size: 12))
                    
                    // Native countdown for lock screen widget
                    Text(timerInterval: Date()...moment.targetDate, countsDown: true)
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
            }
            .widgetAccentable()
        } else {
            Image(systemName: "calendar")
                .font(.title2)
                .widgetAccentable()
        }
    }
}

// MARK: - Time Formatting removed
// Native Text(timerInterval:) is now used for all countdown displays
// which updates automatically without needing widget refreshes


