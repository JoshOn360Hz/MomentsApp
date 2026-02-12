import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Clear notification badge on launch
        UNUserNotificationCenter.current().setBadgeCount(0)
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear notification badge when app becomes active
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
    
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is open
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Extract moment ID and handle navigation
        if let momentId = userInfo["momentId"] as? String {
            print("User tapped notification for moment: \(momentId)")
        }
        
        completionHandler()
    }
}
