import Foundation
import UserNotifications

@MainActor
@Observable
class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }
    

    
    func scheduleNotifications(for moment: Moment) async {
        // Remove existing notifications for this moment
        await removeNotifications(for: moment)
        
        // Check authorization
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }
        
        let targetDate = moment.targetDate
        let now = Date()
        
        // Schedule 24 hours before
        if moment.notifyTwentyFourHours {
            let notificationDate = targetDate.addingTimeInterval(-86400) // 24 hours
            if notificationDate > now {
                await scheduleNotification(
                    for: moment,
                    at: notificationDate,
                    title: "Tomorrow: \(moment.title)",
                    body: "Your moment is happening in 24 hours"
                )
            }
        }
        
        // Schedule 1 hour before
        if moment.notifyOneHour {
            let notificationDate = targetDate.addingTimeInterval(-3600) // 1 hour
            if notificationDate > now {
                await scheduleNotification(
                    for: moment,
                    at: notificationDate,
                    title: "Soon: \(moment.title)",
                    body: "Your moment is happening in 1 hour"
                )
            }
        }
        
        // Schedule 10 minutes before
        if moment.notifyTenMinutes {
            let notificationDate = targetDate.addingTimeInterval(-600) // 10 minutes
            if notificationDate > now {
                await scheduleNotification(
                    for: moment,
                    at: notificationDate,
                    title: "Almost here: \(moment.title)",
                    body: "Your moment is happening in 10 minutes"
                )
            }
        }
    }
    
    private func scheduleNotification(
        for moment: Moment,
        at date: Date,
        title: String,
        body: String
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // Add custom data
        content.userInfo = [
            "momentId": moment.id.uuidString,
            "momentTitle": moment.title
        ]
        
        // Create date components trigger
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request
        let identifier = "\(moment.id.uuidString)-\(date.timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled notification for \(title) at \(date)")
        } catch {
            print("Error scheduling notification: \(error)")
        }
    }

    
    func removeNotifications(for moment: Moment) async {
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()
        
        let identifiersToRemove = pendingRequests
            .filter { request in
                guard let momentId = request.content.userInfo["momentId"] as? String else {
                    return false
                }
                return momentId == moment.id.uuidString
            }
            .map { $0.identifier }
        
        center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        print("Removed \(identifiersToRemove.count) notifications for \(moment.title)")
    }
    
    
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
}
