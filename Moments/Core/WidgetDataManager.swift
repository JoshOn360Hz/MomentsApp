import Foundation
import WidgetKit

// MARK: - Widget Data Sharing

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private init() {}
    
    /// Share moment data with widgets
    func shareMomentsWithWidgets(_ moments: [Moment]) {
        // Convert to simple format for widgets
        let simpleMoments = moments.map { moment in
            SimpleMoment(
                id: moment.id.uuidString,
                title: moment.title,
                targetDate: moment.targetDate,
                accentColorHex: moment.accentColorHex,
                symbolName: moment.symbolName
            )
        }
        
        // Save to App Group UserDefaults
        guard let sharedDefaults = UserDefaults(suiteName: AppGroup.identifier) else {
            return
        }
        
        do {
            let data = try JSONEncoder().encode(simpleMoments)
            sharedDefaults.set(data, forKey: "SharedMoments")
            sharedDefaults.synchronize()
            
            // Trigger widget timeline reload
            WidgetCenter.shared.reloadAllTimelines()
            
        } catch {
            // Encoding failed, widgets will use sample data
        }
    }
}

// MARK: - Simple data structure for widgets (matches SimpleMoment in widgets)

struct SimpleMoment: Codable, Identifiable {
    let id: String
    let title: String
    let targetDate: Date
    let accentColorHex: String
    let symbolName: String
}