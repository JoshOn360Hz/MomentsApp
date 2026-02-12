import Foundation
import ActivityKit
import UIKit

@MainActor
@Observable
class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private init() {}
    
    // Track active activities by moment ID
    private var activeActivities: [String: Activity<MomentsActivityAttributes>] = [:]
    private var isManaging = false // Prevent simultaneous management calls
    private var creatingActivities: Set<String> = [] // Track activities being created
    private var managementTask: Task<Void, Never>? // Debounce management calls
    
    
    func createTestActivity() {
        
        Task {
            let targetDate = Date().addingTimeInterval(3600) // 1 hour from now
            let timeRemaining: TimeInterval = 3600
            let progress = 0.25 // 25% progress
            
            let attributes = MomentsActivityAttributes(
                momentId: "test-countdown",
                title: "New Year Party",
                targetDate: targetDate,
                symbolName: "party.popper",
                accentColorHex: "#FF6B6B",
                showEndTime: true
            )
            
            let contentState = MomentsActivityAttributes.ContentState(
                timeRemaining: timeRemaining,
                progress: progress
            )
            
            do {
                let _ = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(
                        state: contentState,
                        staleDate: nil
                    ),
                    pushType: nil
                )
            } catch {
                // Test failed
            }
        }
    }
    
    /// Start a live activity for a moment with enhanced validation
    func startActivity(for moment: Moment) {
        // Pre-flight checks
        guard canStartActivity(for: moment) else {
            return
        }
        
        // Check if already being created
        if creatingActivities.contains(moment.id.uuidString) {
            return
        }
        
        // Check if already active
        if let existingActivity = activeActivities[moment.id.uuidString] {
            if existingActivity.activityState == .active {
                return
            } else {
                // Clean up non-active activity
                activeActivities.removeValue(forKey: moment.id.uuidString)
            }
        }
        
        // Mark as being created
        creatingActivities.insert(moment.id.uuidString)
        
        Task {
            await createActivity(for: moment)
            // Remove from creating set when done
            creatingActivities.remove(moment.id.uuidString)
        }
    }
    
    /// Update existing activity
    func updateActivity(for moment: Moment) async {
        guard let activity = activeActivities[moment.id.uuidString],
              activity.activityState == .active else {
            return
        }
        
        let contentState = createContentState(for: moment)
        let content = ActivityContent(
            state: contentState,
            staleDate: Date().addingTimeInterval(3600) // 1 hour
        )
        
        do {
            await activity.update(content)
        } catch {
            // Clean up failed activity
            activeActivities.removeValue(forKey: moment.id.uuidString)
        }
    }
    
    /// End activity for a moment
    func endActivity(for moment: Moment) async {
        guard let activity = activeActivities[moment.id.uuidString] else {
            return
        }
        
        await activity.end(
            ActivityContent(state: activity.content.state, staleDate: nil),
            dismissalPolicy: .immediate
        )
        
        activeActivities.removeValue(forKey: moment.id.uuidString)
    }
    
    /// Manage all activities for the current moments
    func manageActivities(for moments: [Moment]) {
        // Prevent simultaneous management calls
        guard !isManaging else {
            return
        }
        
        isManaging = true
        defer { isManaging = false }
        
        // Clean up dismissed activities first
        cleanupDismissedActivities()
        
        // Find moments that should have activities
        let qualifyingMoments = moments.filter { $0.shouldShowLiveActivity }
        
        if qualifyingMoments.isEmpty {
            for (momentId, _) in activeActivities {
                Task {
                    if let moment = moments.first(where: { $0.id.uuidString == momentId }) {
                        await endActivity(for: moment)
                    }
                }
            }
            return
        }
        
        // Only keep one activity - the next upcoming moment
        let nextMoment = qualifyingMoments.min { $0.targetDate < $1.targetDate }
        
        // End activities for moments that shouldn't be active
        for (momentId, activity) in activeActivities {
            if momentId != nextMoment?.id.uuidString {
                Task {
                    if let moment = moments.first(where: { $0.id.uuidString == momentId }) {
                        await endActivity(for: moment)
                    }
                }
            }
        }
        
        // Start the next moment's activity (don't update existing ones to prevent churn)
        if let nextMoment = nextMoment {
            let hasActiveActivity = activeActivities[nextMoment.id.uuidString]?.activityState == .active
            
            if !hasActiveActivity {
                startActivity(for: nextMoment)
            }
        }
    }
    
    // MARK: - Private Implementation
    
    private func canStartActivity(for moment: Moment) -> Bool {
        // Check basic authorization
        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            return false
        }
        
        // Validate moment timing with more strict requirements
        let timeRemaining = moment.timeRemaining
        guard timeRemaining > 300 else { // At least 5 minutes remaining
            return false
        }
        
        // Don't create activities for very long timeframes that iOS might not handle well
        guard timeRemaining < 7 * 24 * 3600 else { // Less than 7 days
            return false
        }
        
        // Check if within threshold
        guard moment.shouldShowLiveActivity else {
            return false
        }
        
        // Validate progress will be meaningful
        let totalDuration = moment.targetDate.timeIntervalSince(moment.createdDate)
        guard totalDuration > 300 else { // At least 5 minutes total duration
            return false
        }
        
        return true
    }
    
    private func createContentState(for moment: Moment) -> MomentsActivityAttributes.ContentState {
        let timeRemaining = max(moment.timeRemaining, 0)
        
        // Use the same enhanced progress calculation as the model
        let totalDuration = moment.targetDate.timeIntervalSince(moment.createdDate)
        let elapsed = Date().timeIntervalSince(moment.createdDate)
        let rawProgress = elapsed / totalDuration
        
        // Use meaningful minimum progress values based on duration
        let minProgress: Double
        if totalDuration > 86400 { // > 1 day
            minProgress = 0.15 // 15% minimum for long events
        } else if totalDuration > 3600 { // > 1 hour
            minProgress = 0.10 // 10% minimum for medium events
        } else {
            minProgress = 0.05 // 5% minimum for short events
        }
        
        let progress = min(max(rawProgress, minProgress), 1.0)
        
        return MomentsActivityAttributes.ContentState(
            timeRemaining: timeRemaining,
            progress: progress
        )
    }
    
    private func createActivity(for moment: Moment) async {
        let attributes = MomentsActivityAttributes(
            momentId: moment.id.uuidString,
            title: moment.title,
            targetDate: moment.targetDate,
            symbolName: moment.symbolName,
            accentColorHex: moment.accentColorHex,
            showEndTime: moment.showEndTimeInLiveActivity
        )
        
        let contentState = createContentState(for: moment)
        guard !attributes.title.isEmpty else {
            return
        }
        
        guard attributes.targetDate > Date() else {
            return
        }
        
        guard !attributes.symbolName.isEmpty else {
            return
        }
        
      
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(
                    state: contentState,
                    staleDate: nil
                ),
                pushType: nil
            )
            
            activeActivities[moment.id.uuidString] = activity
        } catch {
            // Activity creation failed
        }
    }
    
    private func cleanupDismissedActivities() {
        var toRemove: [String] = []
        
        for (momentId, activity) in activeActivities {
            if activity.activityState != .active {
                toRemove.append(momentId)
            }
        }
        
        for momentId in toRemove {
            activeActivities.removeValue(forKey: momentId)
        }
    }
        
        // MARK: - Diagnostics
        
        func diagnostics() {
            // Diagnostics available for debugging if needed
        }
        
        // MARK: - Legacy Compatibility
        
        /// Legacy method for backward compatibility with debouncing
        func checkAndManageActivities(for moments: [Moment]) {
            // Cancel any existing management task
            managementTask?.cancel()
            
            // Create new debounced task
            managementTask = Task {
                // Debounce: wait to see if more calls come in quickly
                try? await Task.sleep(for: .milliseconds(150))
                
                // Check if task was cancelled (new call came in)
                guard !Task.isCancelled else {
                    return
                }
                
                // Execute the actual management
                manageActivities(for: moments)
            }
        }
}

