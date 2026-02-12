
import Foundation

struct TimeEngine {
    
    
    // Formats time remaining in a human-readable string
    static func formattedTimeRemaining(for moment: Moment) -> String {
        let interval = moment.timeRemaining
        
        if interval <= 0 {
            return "Now"
        }
        
        let seconds = Int(interval)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        let weeks = days / 7
        let months = days / 30
        let years = days / 365
        
        // Format based on scale
        if years > 0 {
            return years == 1 ? "1 year" : "\(years) years"
        } else if months > 0 {
            return months == 1 ? "1 month" : "\(months) months"
        } else if weeks > 0 {
            return weeks == 1 ? "1 week" : "\(weeks) weeks"
        } else if days > 0 {
            return days == 1 ? "1 day" : "\(days) days"
        } else if hours > 0 {
            return hours == 1 ? "1 hour" : "\(hours) hours"
        } else if minutes > 0 {
            return minutes == 1 ? "1 min" : "\(minutes) mins"
        } else {
            return seconds == 1 ? "1 sec" : "\(seconds) secs"
        }
    }
    
    /// Compact format for widgets and small spaces
    static func compactTimeRemaining(for moment: Moment) -> String {
        let interval = moment.timeRemaining
        
        if interval <= 0 {
            return "Now"
        }
        
        let seconds = Int(interval)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        let weeks = days / 7
        
        if weeks > 0 {
            return "\(weeks)w"
        } else if days > 0 {
            return "\(days)d"
        } else if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
    
    /// Detailed countdown format (HH:MM:SS or DD HH MM)
    static func detailedCountdown(for moment: Moment) -> String {
        let interval = moment.timeRemaining
        
        if interval <= 0 {
            return "00:00:00"
        }
        
        let seconds = Int(interval)
        let minutes = (seconds / 60) % 60
        let hours = (seconds / 3600) % 24
        let days = seconds / 86400
        
        if days > 0 {
            return String(format: "%dd %02dh %02dm", days, hours, minutes)
        } else {
            let secs = seconds % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        }
    }
    
    
    // Calculate progress ratio (0.0 to 1.0)
    static func calculateProgress(for moment: Moment) -> Double {
        return moment.progress
    }
    
    
    // Determine next refresh date for widgets
    static func nextRefreshDate(for moment: Moment) -> Date {
        let interval = moment.timeRemaining
        
        // If past, refresh in an hour
        if interval <= 0 {
            return Date().addingTimeInterval(3600)
        }
        
        let seconds = Int(interval)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        
        // Smart refresh strategy
        if days > 7 {
            // Far away: refresh daily
            return Date().addingTimeInterval(86400)
        } else if days > 1 {
            // Within a week: refresh every 6 hours
            return Date().addingTimeInterval(21600)
        } else if hours > 1 {
            // Within a day: refresh hourly
            return Date().addingTimeInterval(3600)
        } else if minutes > 10 {
            // Within an hour: refresh every 10 minutes
            return Date().addingTimeInterval(600)
        } else {
            // Final countdown: refresh every minute
            return Date().addingTimeInterval(60)
        }
    }
    
    
    // Sort moments by proximity (nearest first)
    static func sortedByProximity(_ moments: [Moment]) -> [Moment] {
        return moments.sorted { abs($0.timeRemaining) < abs($1.timeRemaining) }
    }
    
    // Filter upcoming moments (not completed, not past)
    static func upcomingMoments(_ moments: [Moment]) -> [Moment] {
        return moments.filter { !$0.isCompleted && $0.timeRemaining > 0 }
    }
    
    // Filter completed moments
    static func completedMoments(_ moments: [Moment]) -> [Moment] {
        return moments.filter { $0.isCompleted || $0.timeRemaining <= 0 }
    }
    
    
    static func formattedTargetDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    static func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
