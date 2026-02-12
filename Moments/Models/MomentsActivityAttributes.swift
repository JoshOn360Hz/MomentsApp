//
//  MomentsActivityAttributes.swift
//  Moments
//
//  Created by Josh Mansfield on 12/02/2026.
//

import ActivityKit
import Foundation


struct MomentsActivityAttributes: ActivityAttributes, Codable, Hashable {
    public struct ContentState: Codable, Hashable {
        var timeRemaining: TimeInterval
        var progress: Double
    }
    
    var momentId: String
    var title: String
    var targetDate: Date
    var symbolName: String
    var accentColorHex: String
    var showEndTime: Bool
}
