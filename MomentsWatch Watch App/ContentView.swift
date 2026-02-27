import SwiftUI
import Combine
import WatchConnectivity

// MARK: - Watch Connectivity Manager

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var moments: [SimpleMoment] = []
    
    private let momentsKey = "WatchMoments"
    
    private override init() {
        super.init()
        
        // Load cached moments first
        loadCachedMoments()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    private func loadCachedMoments() {
        guard let data = UserDefaults.standard.data(forKey: momentsKey),
              let decoded = try? JSONDecoder().decode([SimpleMoment].self, from: data) else {
            return
        }
        moments = sortMoments(decoded)
    }
    
    private func saveMoments(_ moments: [SimpleMoment]) {
        if let data = try? JSONEncoder().encode(moments) {
            UserDefaults.standard.set(data, forKey: momentsKey)
        }
    }
    
    private func sortMoments(_ moments: [SimpleMoment]) -> [SimpleMoment] {
        // Only show upcoming moments, remove completed ones
        return moments
            .filter { !$0.isPast }
            .sorted { $0.targetDate < $1.targetDate }
    }
    
    private func processMomentsData(_ momentsData: [[String: Any]]) {
        let decoded = momentsData.compactMap { dict -> SimpleMoment? in
            guard let id = dict["id"] as? String,
                  let title = dict["title"] as? String,
                  let targetTimestamp = dict["targetDate"] as? TimeInterval,
                  let createdTimestamp = dict["createdDate"] as? TimeInterval,
                  let accentColorHex = dict["accentColorHex"] as? String,
                  let symbolName = dict["symbolName"] as? String else {
                return nil
            }
            
            return SimpleMoment(
                id: id,
                title: title,
                targetDate: Date(timeIntervalSince1970: targetTimestamp),
                createdDate: Date(timeIntervalSince1970: createdTimestamp),
                accentColorHex: accentColorHex,
                symbolName: symbolName
            )
        }
        
        DispatchQueue.main.async {
            self.moments = self.sortMoments(decoded)
            self.saveMoments(decoded)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Check for any existing application context
        if let momentsData = session.receivedApplicationContext["moments"] as? [[String: Any]] {
            processMomentsData(momentsData)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let momentsData = message["moments"] as? [[String: Any]] {
            processMomentsData(momentsData)
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let momentsData = applicationContext["moments"] as? [[String: Any]] {
            processMomentsData(momentsData)
        }
    }
}

// MARK: - Shared Moment Model

struct SimpleMoment: Codable, Identifiable {
    let id: String
    let title: String
    let targetDate: Date
    let createdDate: Date
    let accentColorHex: String
    let symbolName: String
    
    var accentColor: Color {
        Color(hex: accentColorHex) ?? .blue
    }
    
    var timeRemaining: TimeInterval {
        targetDate.timeIntervalSinceNow
    }
    
    var progress: Double {
        let totalDuration = targetDate.timeIntervalSince(createdDate)
        let elapsed = Date().timeIntervalSince(createdDate)
        let rawProgress = elapsed / totalDuration
        
        let minProgress: Double
        if totalDuration > 86400 {
            minProgress = 0.15
        } else if totalDuration > 3600 {
            minProgress = 0.10
        } else {
            minProgress = 0.05
        }
        
        return min(max(rawProgress, minProgress), 1.0)
    }
    
    var isPast: Bool {
        timeRemaining <= 0
    }
}

// MARK: - Content View

struct ContentView: View {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Filter out expired moments dynamically
    private var activeMoments: [SimpleMoment] {
        connectivityManager.moments.filter { $0.targetDate > currentTime }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if activeMoments.isEmpty {
                    emptyState
                } else {
                    momentsList
                }
            }
            .navigationTitle("Moments")
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                // Animated rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.blue.opacity(0.4), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: CGFloat(50 + i * 20), height: CGFloat(50 + i * 20))
                        .opacity(Double(3 - i) / 3)
                }
                
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 6) {
                Text("No Moments")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("Open Moments on\nyour iPhone to sync")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    
    private var momentsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(activeMoments) { moment in
                    NavigationLink(destination: MomentDetailView(moment: moment)) {
                        MomentCardView(moment: moment, currentTime: currentTime)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Moment Card View

struct MomentCardView: View {
    let moment: SimpleMoment
    let currentTime: Date
    
    var body: some View {
        VStack(spacing: 0) {
            // Top section with icon and progress
            HStack(spacing: 12) {
                // Circular progress with icon
                ZStack {
                    Circle()
                        .stroke(moment.accentColor.opacity(0.25), lineWidth: 4)
                        .frame(width: 48, height: 48)
                    
                    Circle()
                        .trim(from: 0, to: moment.progress)
                        .stroke(
                            moment.accentColor,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 48, height: 48)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: moment.symbolName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(moment.accentColor)
                        .symbolRenderingMode(.hierarchical)
                }
                .id(currentTime) // Force refresh on timer tick
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(moment.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    if moment.isPast {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                            Text("Complete")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.green)
                    } else {
                        // Native countdown
                        Text(timerInterval: Date()...moment.targetDate, countsDown: true)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(moment.accentColor)
                            .monospacedDigit()
                    }
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            moment.accentColor.opacity(0.2),
                            moment.accentColor.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(moment.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
