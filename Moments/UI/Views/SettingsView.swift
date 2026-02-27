import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("defaultNotifications") private var defaultNotifications = true
    @AppStorage("defaultLiveActivity") private var defaultLiveActivity = true
    @AppStorage("defaultAccentColor") private var defaultAccentColor = "#007AFF"
    @AppStorage("defaultLiveActivityThresholdMinutes") private var defaultLiveActivityThresholdMinutes = 1440 // 1 day
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showOnboarding = false
    @StateObject private var watchManager = WatchConnectivityManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                // Accent Color Section
                Section {
                    InlineColorPickerGrid(selectedColorHex: $defaultAccentColor)
                        .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                } header: {
                    Text("Accent Color")
                }
                
                // Default Settings Section
                Section {
                    Toggle(isOn: $defaultNotifications) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notifications")
                            
                            Text("Enable for new moments")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.orange)
                    
                    Toggle(isOn: $defaultLiveActivity) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Live Activities")
                            
                            Text("Show on Lock Screen by default")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.green)
                    
                    Picker("Show Within", selection: $defaultLiveActivityThresholdMinutes) {
                        Text("1 Day").tag(1440)
                        Text("3 Days").tag(4320)
                        Text("1 Week").tag(10080)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Default Settings")
                } footer: {
                    Text("These settings apply to newly created moments")
                        .font(.caption)
                }
                
                // Apple Watch Section
                Section {
                    if watchManager.isSupported && watchManager.isWatchPaired {
                        // Watch is paired - show detailed status
                        HStack {
                            Image(systemName: "applewatch")
                                .font(.title2)
                                .foregroundStyle(.green)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Apple Watch")
                                Text("Connected")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        
                        HStack {
                            Image(systemName: "app.badge")
                                .font(.title2)
                                .foregroundStyle(watchManager.isWatchAppInstalled ? .blue : .secondary)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("App Installed")
                                Text(watchManager.isWatchAppInstalled ? "Ready to sync" : "Install from Watch app")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: watchManager.isWatchAppInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(watchManager.isWatchAppInstalled ? .green : .orange)
                        }
                        
                        if watchManager.isWatchAppInstalled {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.title2)
                                    .foregroundStyle(watchManager.isReachable ? .green : .secondary)
                                    .frame(width: 32)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Reachable")
                                    Text(watchManager.isReachable ? "Watch is nearby" : "Watch not in range")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Circle()
                                    .fill(watchManager.isReachable ? .green : .gray)
                                    .frame(width: 10, height: 10)
                            }
                            
                            if let lastSync = watchManager.lastSyncDate {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 32)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Last Synced")
                                        Text(lastSync, style: .relative)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    } else {
                        // No watch paired - simple message
                        HStack {
                            Image(systemName: "applewatch.slash")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                                .frame(width: 32)
                            
                            Text("No Apple Watch connected")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Apple Watch")
                } footer: {
                    if watchManager.isWatchAppInstalled {
                        Text("Moments sync automatically when you open this app")
                            .font(.caption)
                    }
                }
                
                // Onboarding Section
                Section {
                    Button(action: { showOnboarding = true }) {
                        HStack {
                            Text("Replay Onboarding")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("Help")
                } footer: {
                    Text("Learn about all the features Moments has to offer")
                        .font(.caption)
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    
                    Link(destination: URL(string: "https://joshon360hz.github.io/Moments/#privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://joshon360hz.github.io/Moments/#support")!) {
                        HStack {
                            Text("Support")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("About")
                }
                
                // Credits Section
                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolEffect(.pulse)
                        
                        Text("Count what matters")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showOnboarding) {
                OnboardingView()
            }
            .task {
                await checkNotificationPermissions()
            }
        }
    }
    
    // MARK: - Notification Status Helpers
    
    private var notificationStatusColor: Color {
        switch notificationStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined, .provisional, .ephemeral:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    private var notificationStatusIcon: String {
        switch notificationStatus {
        case .authorized:
            return "bell.fill"
        case .denied:
            return "bell.slash.fill"
        case .notDetermined, .provisional, .ephemeral:
            return "bell.badge"
        @unknown default:
            return "bell"
        }
    }
    
    private var notificationStatusText: String {
        switch notificationStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Disabled - Enable in Settings"
        case .notDetermined:
            return "Not yet requested"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Temporary"
        @unknown default:
            return "Unknown"
        }
    }
    
    // MARK: - Actions
    
    private func checkNotificationPermissions() async {
        notificationStatus = await NotificationManager.shared.checkAuthorizationStatus()
    }
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

#Preview {
    SettingsView()
}
