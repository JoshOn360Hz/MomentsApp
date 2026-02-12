import Foundation

enum AppGroup {
    static let identifier = "group.moments.shareddata"
    
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}
