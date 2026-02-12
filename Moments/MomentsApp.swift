import SwiftUI
import SwiftData

@main
struct MomentsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Moment.self,
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(AppGroup.identifier)
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .task {
                        // Request notification permission on first launch
                        await requestNotificationPermissionIfNeeded()
                    }
            } else {
                OnboardingView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
    
    
    private func requestNotificationPermissionIfNeeded() async {
        let status = await NotificationManager.shared.checkAuthorizationStatus()
        
        // Only request if not determined yet
        if status == .notDetermined {
            _ = await NotificationManager.shared.requestAuthorization()
        }
    }
}
