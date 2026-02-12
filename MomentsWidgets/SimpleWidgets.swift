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
    let accentColorHex: String
    let symbolName: String
    
    var accentColor: Color {
        Color(hex: accentColorHex) ?? .blue
    }
    
    var timeRemaining: TimeInterval {
        targetDate.timeIntervalSinceNow
    }
    
    var progress: Double {
        // Estimate creation date (30 days ago for fallback)
        let estimatedCreationDate = Date().addingTimeInterval(-86400 * 30)
        let totalDuration = targetDate.timeIntervalSince(estimatedCreationDate)
        let elapsed = Date().timeIntervalSince(estimatedCreationDate)
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
        
        // Create entries for next few updates
        var entries: [SimpleMomentsEntry] = []
        
        // More frequent updates for better countdown accuracy
        let updateInterval: TimeInterval
        if let firstMoment = moments.first {
            let timeRemaining = firstMoment.timeRemaining
            if timeRemaining < 3600 { // Less than 1 hour
                updateInterval = 60 // Update every minute
            } else if timeRemaining < 86400 { // Less than 24 hours
                updateInterval = 300 // Update every 5 minutes
            } else {
                updateInterval = 900 // Update every 15 minutes
            }
        } else {
            updateInterval = 3600 // No moments, update hourly
        }
        
        // Create 20 timeline entries
        for i in 0..<20 {
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
                accentColorHex: "#FF2D55",
                symbolName: "party.popper.fill"
            ),
            SimpleMoment(
                id: "sample-2", 
                title: "Sample Meeting",
                targetDate: Date().addingTimeInterval(3600 * 4),
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
                
                Text(formatTimeRemaining(moment.timeRemaining))
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
                        
                        Text(formatTimeRemaining(moment.timeRemaining))
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
                    
                    Text(formatTimeRemainingShort(moment.timeRemaining))
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

// MARK: - Time Formatting

private func formatTimeRemaining(_ interval: TimeInterval) -> String {
    let days = Int(interval) / 86400
    let hours = Int(interval) % 86400 / 3600
    let minutes = Int(interval) % 3600 / 60
    
    if days > 0 {
        return "\(days)d \(hours)h"
    } else if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else if minutes > 0 {
        return "\(minutes)m"
    } else {
        return "\(max(0, Int(interval)))s"
    }
}

private func formatTimeRemainingShort(_ interval: TimeInterval) -> String {
    let days = Int(interval) / 86400
    let hours = Int(interval) % 86400 / 3600
    let minutes = Int(interval) % 3600 / 60
    
    if days > 0 {
        return "\(days)d"
    } else if hours > 0 {
        return "\(hours)h"
    } else if minutes > 0 {
        return "\(minutes)m"
    } else {
        return "\(max(0, Int(interval)))s"
    }
}


