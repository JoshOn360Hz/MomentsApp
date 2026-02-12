
import Foundation
import SwiftData
import SwiftUI

@Model
final class Moment {
    var id: UUID
    var title: String
    var targetDate: Date
    var createdDate: Date
    
    // Visual customization
    var accentColorHex: String
    var symbolName: String
    
    // Advanced settings
    var repeatYearly: Bool
    var autoDeleteAfterCompletion: Bool
    var liveActivityThresholdMinutes: Int // Minutes before event to trigger Live Activity
    var showEndTimeInLiveActivity: Bool
    
    // Notifications
    var notifyTwentyFourHours: Bool
    var notifyOneHour: Bool
    var notifyTenMinutes: Bool
    
    // Metadata
    var isCompleted: Bool
    var completedDate: Date?
    
    init(
        title: String,
        targetDate: Date,
        accentColorHex: String = "#007AFF",
        symbolName: String = "star.fill",
        repeatYearly: Bool = false,
        autoDeleteAfterCompletion: Bool = false,
        liveActivityThresholdMinutes: Int = 60,
        showEndTimeInLiveActivity: Bool = true,
        notifyTwentyFourHours: Bool = false,
        notifyOneHour: Bool = false,
        notifyTenMinutes: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.targetDate = targetDate
        self.createdDate = Date()
        self.accentColorHex = accentColorHex
        self.symbolName = symbolName
        self.repeatYearly = repeatYearly
        self.autoDeleteAfterCompletion = autoDeleteAfterCompletion
        self.liveActivityThresholdMinutes = liveActivityThresholdMinutes
        self.showEndTimeInLiveActivity = showEndTimeInLiveActivity
        self.notifyTwentyFourHours = notifyTwentyFourHours
        self.notifyOneHour = notifyOneHour
        self.notifyTenMinutes = notifyTenMinutes
        self.isCompleted = false
        self.completedDate = nil
    }
    
    // Computed properties
    var accentColor: Color {
        Color(hex: accentColorHex) ?? .blue
    }
    
    var timeRemaining: TimeInterval {
        targetDate.timeIntervalSinceNow
    }
    
    var hasStarted: Bool {
        timeRemaining <= 0
    }
    
    var progress: Double {
        let totalDuration = targetDate.timeIntervalSince(createdDate)
        let elapsed = Date().timeIntervalSince(createdDate)
        let rawProgress = elapsed / totalDuration
        
        // For Live Activities, use much higher minimum progress to prevent dismissal
        // iOS seems to dismiss activities with very small progress values on device
        let minProgress: Double
        if totalDuration > 86400 { // > 1 day
            minProgress = 0.15 // 15% minimum for long events
        } else if totalDuration > 3600 { // > 1 hour  
            minProgress = 0.10 // 10% minimum for medium events
        } else {
            minProgress = 0.05 // 5% minimum for short events
        }
        
        return min(max(rawProgress, minProgress), 1)
    }
    
    var shouldShowLiveActivity: Bool {
        let thresholdSeconds = TimeInterval(liveActivityThresholdMinutes * 60)
        let remaining = timeRemaining
        
        // Don't show if moment has passed
        guard remaining > 0 else { return false }
        
        // Don't show if still too far away  
        guard remaining <= thresholdSeconds else { return false }
        
        // Don't show if too close (less than 5 minutes remaining) - aligns with LiveActivityManager
        guard remaining > 300 else { return false }
        
        // Don't show if too far away (more than 7 days) - aligns with LiveActivityManager
        guard remaining < 7 * 24 * 3600 else { return false }
        
        // Ensure total duration is reasonable
        let totalDuration = targetDate.timeIntervalSince(createdDate)
        guard totalDuration > 300 else { return false }
        
        return true
    }
}

// MARK: - Color Extension for Hex Support
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
    
    func toHex() -> String? {
        let uiColor = UIColor(self)
        guard let components = uiColor.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}
