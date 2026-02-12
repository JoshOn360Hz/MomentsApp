import WidgetKit
import SwiftUI

@main
struct MomentsWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // Simple home screen widgets
        SmallMomentsWidget()
        MediumMomentsWidget()
        
        // Simple lock screen widget
        CircularLockWidget()
                
        // Live Activities
        MomentsLiveActivity()
    }
}
