import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isWatchPaired: Bool = false
    @Published var isWatchAppInstalled: Bool = false
    @Published var isReachable: Bool = false
    @Published var lastSyncDate: Date?
    
    var isSupported: Bool {
        WCSession.isSupported()
    }
    
    private override init() {
        super.init()
        
        // Load last sync date
        lastSyncDate = UserDefaults.standard.object(forKey: "WatchLastSyncDate") as? Date
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    private func updateStatus() {
        DispatchQueue.main.async {
            if WCSession.isSupported() {
                let session = WCSession.default
                self.isWatchPaired = session.isPaired
                self.isWatchAppInstalled = session.isWatchAppInstalled
                self.isReachable = session.isReachable
            }
        }
    }
    
    /// Send moments to the Watch
    func sendMomentsToWatch(_ moments: [Moment]) {
        guard WCSession.default.activationState == .activated else {
            return
        }
        
        // Convert to simple format
        let simpleMoments = moments.map { moment in
            [
                "id": moment.id.uuidString,
                "title": moment.title,
                "targetDate": moment.targetDate.timeIntervalSince1970,
                "createdDate": moment.createdDate.timeIntervalSince1970,
                "accentColorHex": moment.accentColorHex,
                "symbolName": moment.symbolName
            ] as [String: Any]
        }
        
        let message = ["moments": simpleMoments]
        
        // Use applicationContext for persistent data that survives app restarts
        do {
            try WCSession.default.updateApplicationContext(message)
            DispatchQueue.main.async {
                self.lastSyncDate = Date()
                UserDefaults.standard.set(self.lastSyncDate, forKey: "WatchLastSyncDate")
            }
        } catch {
            print("Failed to send to watch: \(error)")
        }
        
        // Also try to send immediately if watch is reachable
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Failed to send message: \(error)")
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error)")
        }
        updateStatus()
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        updateStatus()
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session
        WCSession.default.activate()
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        updateStatus()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        updateStatus()
    }
}
