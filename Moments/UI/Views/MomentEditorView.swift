import SwiftUI
import SwiftData
import WidgetKit

struct MomentEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultNotifications") private var defaultNotifications = true
    @AppStorage("defaultLiveActivity") private var defaultLiveActivity = true
    @AppStorage("defaultAccentColor") private var defaultAccentColor = "#007AFF"
    @AppStorage("defaultLiveActivityThresholdMinutes") private var defaultLiveActivityThresholdMinutes = 1440
    @Query private var allMoments: [Moment]
    
    var existingMoment: Moment?
    
    @State private var title = ""
    @State private var targetDate = Date().addingTimeInterval(86400)
    @State private var selectedColorHex = "#007AFF"
    @State private var selectedSymbol = "star.fill"
    @State private var showingSymbolPicker = false
    @State private var showingColorPicker = false
    
    // Notifications 
    @State private var notificationTiming: NotificationTiming = .none
    @State private var showLiveActivity = true
    @State private var showPermissionAlert = false
    
    enum NotificationTiming: String, CaseIterable {
        case none = "None"
        case tenMinutes = "10 min"
        case oneHour = "1 hour"
        case twentyFourHours = "24 hours"
        case all = "All"
        
        var notifications: (h24: Bool, h1: Bool, m10: Bool) {
            switch self {
            case .none: return (false, false, false)
            case .tenMinutes: return (false, false, true)
            case .oneHour: return (false, true, false)
            case .twentyFourHours: return (true, false, false)
            case .all: return (true, true, true)
            }
        }
    }
    
    var isEditing: Bool {
        existingMoment != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section {
                    TextField("Title", text: $title)
                        .font(.body)
                    
                    DatePicker(
                        "Target Date",
                        selection: $targetDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                } header: {
                    Text("Basic Information")
                }
                
                // Appearance Section - Side by Side
                Section {
                    HStack(spacing: 16) {
                        // Color Picker
                        VStack(spacing: 8) {
                            Button {
                                showingColorPicker = true
                            } label: {
                                VStack(spacing: 12) {
                                    Circle()
                                        .fill(Color(hex: selectedColorHex) ?? .blue)
                                        .frame(width: 60, height: 60)
                                        .overlay {
                                            Circle()
                                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                                        }
                                        .shadow(color: (Color(hex: selectedColorHex) ?? .blue).opacity(0.3), radius: 8, y: 4)
                                    
                                    Text("Color")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Divider()
                        
                        // Icon Picker
                        VStack(spacing: 8) {
                            Button {
                                showingSymbolPicker = true
                            } label: {
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill((Color(hex: selectedColorHex) ?? .blue).opacity(0.15))
                                            .frame(width: 60, height: 60)
                                        
                                        Image(systemName: selectedSymbol)
                                            .font(.system(size: 28))
                                            .foregroundStyle(Color(hex: selectedColorHex) ?? .blue)
                                    }
                                    
                                    Text("Icon")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Appearance")
                }
                
                // Notifications Section
                Section {
                    Picker("Remind Me", selection: $notificationTiming) {
                        ForEach(NotificationTiming.allCases, id: \.self) { timing in
                            Text(timing.rawValue).tag(timing)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: notificationTiming) { _, newValue in
                        if newValue != .none {
                            Task { await checkNotificationPermission() }
                        }
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    Text(notificationFooterText)
                        .font(.caption)
                }
                
                // Live Activity Section
                Section {
                    Toggle(isOn: $showLiveActivity) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Live Activity")
                                .font(.body)
                            
                            Text("Lock Screen & Dynamic Island")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(Color(hex: selectedColorHex) ?? .blue)
                } header: {
                    Text("Live Activity")
                } footer: {
                    Text("Display real-time countdown on your Lock Screen")
                        .font(.caption)
                }
                
                // Delete Button (if editing)
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            deleteMoment()
                        } label: {
                            Text("Delete Moment")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Moment" : "New Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingColorPicker) {
                NavigationStack {
                    ColorPickerGrid(selectedColorHex: $selectedColorHex)
                        .navigationTitle("Choose Color")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showingColorPicker = false
                                }
                                .fontWeight(.semibold)
                            }
                        }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingSymbolPicker) {
                NavigationStack {
                    SymbolPickerView(selectedSymbol: $selectedSymbol)
                        .navigationTitle("Choose Icon")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showingSymbolPicker = false
                                }
                                .fontWeight(.semibold)
                            }
                        }
                }
                .presentationDetents([.large])
            }
            .onAppear {
                loadDefaults()
                loadExistingMoment()
            }
            .alert("Notifications Disabled", isPresented: $showPermissionAlert) {
                Button("Open Settings") {
                    openAppSettings()
                }
                Button("Cancel", role: .cancel) {
                    // Reset notification timing
                    notificationTiming = .none
                }
            } message: {
                Text("Please enable notifications in Settings to receive reminders for your moments.")
            }
        }
    }
    
    
    private var notificationFooterText: String {
        switch notificationTiming {
        case .none:
            return "No reminders will be sent"
        case .tenMinutes:
            return "Reminder 10 minutes before"
        case .oneHour:
            return "Reminder 1 hour before"
        case .twentyFourHours:
            return "Reminder 24 hours before"
        case .all:
            return "Reminders at 24h, 1h, and 10m before"
        }
    }
    
    
    private func loadDefaults() {
        // Only apply defaults for new moments
        guard existingMoment == nil else { return }
        
        selectedColorHex = defaultAccentColor
        showLiveActivity = defaultLiveActivity
        
        if defaultNotifications {
            notificationTiming = .all
        } else {
            notificationTiming = .none
        }
    }
    
    private func loadExistingMoment() {
        guard let moment = existingMoment else { return }
        
        title = moment.title
        targetDate = moment.targetDate
        selectedColorHex = moment.accentColorHex
        selectedSymbol = moment.symbolName
        showLiveActivity = moment.liveActivityThresholdMinutes > 0
        
        // Derive notification timing from existing bools
        if moment.notifyTwentyFourHours && moment.notifyOneHour && moment.notifyTenMinutes {
            notificationTiming = .all
        } else if moment.notifyTwentyFourHours {
            notificationTiming = .twentyFourHours
        } else if moment.notifyOneHour {
            notificationTiming = .oneHour
        } else if moment.notifyTenMinutes {
            notificationTiming = .tenMinutes
        } else {
            notificationTiming = .none
        }
    }
    
    private func save() {
        let notifications = notificationTiming.notifications
        let liveActivityThreshold = showLiveActivity ? defaultLiveActivityThresholdMinutes : 0
        
        if let moment = existingMoment {
            // Update existing
            moment.title = title
            moment.targetDate = targetDate
            moment.accentColorHex = selectedColorHex
            moment.symbolName = selectedSymbol
            moment.notifyTwentyFourHours = notifications.h24
            moment.notifyOneHour = notifications.h1
            moment.notifyTenMinutes = notifications.m10
            moment.liveActivityThresholdMinutes = liveActivityThreshold
            
            // Save changes to shared container
            try? modelContext.save()
            
            // Update notifications
            Task {
                await NotificationManager.shared.scheduleNotifications(for: moment)
            }
            
            // Restart Live Activity with updated attributes
            Task {
                await LiveActivityManager.shared.endActivity(for: moment)
                LiveActivityManager.shared.checkAndManageActivities(for: allMoments)
            }
            
            // Reload widgets after saving
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            // Create new
            let newMoment = Moment(
                title: title,
                targetDate: targetDate,
                accentColorHex: selectedColorHex,
                symbolName: selectedSymbol,
                liveActivityThresholdMinutes: liveActivityThreshold,
                notifyTwentyFourHours: notifications.h24,
                notifyOneHour: notifications.h1,
                notifyTenMinutes: notifications.m10
            )
            modelContext.insert(newMoment)
            
            // Save to shared container
            try? modelContext.save()
            
            // Schedule notifications
            Task {
                await NotificationManager.shared.scheduleNotifications(for: newMoment)
            }
            
            // Start Live Activity
            Task {
                LiveActivityManager.shared.checkAndManageActivities(for: allMoments)
            }
            
            // Reload widgets after saving
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        dismiss()
    }
    
    private func deleteMoment() {
        guard let existingMoment else { return }
        
        // Cancel notifications
        Task {
            await NotificationManager.shared.removeNotifications(for: existingMoment)
        }
        
        // End Live Activity
        Task {
            await LiveActivityManager.shared.endActivity(for: existingMoment)
        }
        
        // Delete from SwiftData
        modelContext.delete(existingMoment)
        
        // Save deletion to shared container
        try? modelContext.save()
        
        // Check remaining moments for Live Activities
        Task {
            LiveActivityManager.shared.checkAndManageActivities(for: allMoments.filter { $0.id != existingMoment.id })
        }
        
        // Reload widgets after deletion
        WidgetCenter.shared.reloadAllTimelines()
        
        dismiss()
    }
    
    // MARK: - Permissions
    
    private func checkNotificationPermission() async {
        let status = await NotificationManager.shared.checkAuthorizationStatus()
        
        if status == .notDetermined {
            // Request permission
            let granted = await NotificationManager.shared.requestAuthorization()
            if !granted {
                showPermissionAlert = true
            }
        } else if status == .denied {
            // Show alert to open settings
            showPermissionAlert = true
        }
        // If authorized, do nothing - let them enable notifications
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

#Preview("New Moment") {
    MomentEditorView()
        .modelContainer(for: Moment.self, inMemory: true)
}

#Preview("Edit Moment") {
    MomentEditorView(
        existingMoment: Moment(
            title: "Summer Vacation",
            targetDate: Date().addingTimeInterval(86400 * 30),
            accentColorHex: "#FF9500",
            symbolName: "sun.max.fill"
        )
    )
    .modelContainer(for: Moment.self, inMemory: true)
}
