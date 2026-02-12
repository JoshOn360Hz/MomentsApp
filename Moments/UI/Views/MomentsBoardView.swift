import SwiftUI
import SwiftData
import Combine
import WidgetKit

struct MomentsBoardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Moment.targetDate, order: .forward) private var allMoments: [Moment]
    @AppStorage("defaultAccentColor") private var defaultAccentColor = "#007AFF"
    
    @State private var selectedSegment = 0
    @State private var searchText = ""
    @State private var currentTime = Date()
    
    // Timer to refresh countdowns
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var segments = ["Upcoming", "Completed"]
    
    private var filteredMoments: [Moment] {
        let filtered: [Moment]
        
        switch selectedSegment {
        case 0: // Upcoming
            filtered = TimeEngine.upcomingMoments(allMoments)
        case 1: // Completed
            filtered = TimeEngine.completedMoments(allMoments)
        default:
            filtered = allMoments
        }
        
        if searchText.isEmpty {
            return TimeEngine.sortedByProximity(filtered)
        } else {
            return filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Enhanced background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.5),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if filteredMoments.isEmpty {
                    emptyState
                } else {
                    momentsList
                        .id(currentTime)
                }
            }
            .navigationTitle("Moments")
            .searchable(text: $searchText, prompt: "Search moments")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Filter", selection: $selectedSegment) {
                            Text("Upcoming").tag(0)
                            Text("Completed").tag(1)
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(Color(hex: defaultAccentColor) ?? .blue)
                    }
                }
            }
            .onReceive(timer) { _ in
                currentTime = Date()
            }
            .task {
                // Initial check when view appears
                LiveActivityManager.shared.checkAndManageActivities(for: allMoments)
            }
            .onChange(of: allMoments.count) { _, _ in
                // Re-check when moments are added or removed
                LiveActivityManager.shared.checkAndManageActivities(for: allMoments)
            }
        }
    }
    
    
    private var momentsList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(filteredMoments) { moment in
                    NavigationLink {
                        MomentDetailView(moment: moment)
                    } label: {
                        MomentTileView(moment: moment, style: .compact)
                            .transition(.scale.combined(with: .opacity))
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            duplicate(moment)
                        } label: {
                            Label("Duplicate", systemImage: "plus.square.on.square")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            delete(moment)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation(.spring(response: 0.3)) {
                                delete(moment)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: filteredMoments.count)
    }
    
    
    private var emptyState: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                // Outer glow
                Circle()
                    .fill((Color(hex: defaultAccentColor) ?? .blue).opacity(0.15))
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                // Inner circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 130, height: 130)
                    .overlay {
                        Circle()
                            .strokeBorder((Color(hex: defaultAccentColor) ?? .blue).opacity(0.3), lineWidth: 1)
                    }
                
                // Icon
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: defaultAccentColor) ?? .blue,
                                (Color(hex: defaultAccentColor) ?? .blue).opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text(selectedSegment == 0 ? "No Upcoming Moments" : "No Completed Moments")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(selectedSegment == 0 ? 
                     "Tap the + button to create\nyour first moment" :
                     "Completed moments will appear here")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
        .padding()
    }
    
    
    private func duplicate(_ moment: Moment) {
        let newMoment = Moment(
            title: "\(moment.title) Copy",
            targetDate: moment.targetDate,
            accentColorHex: moment.accentColorHex,
            symbolName: moment.symbolName,
            repeatYearly: moment.repeatYearly,
            autoDeleteAfterCompletion: moment.autoDeleteAfterCompletion,
            liveActivityThresholdMinutes: moment.liveActivityThresholdMinutes,
            showEndTimeInLiveActivity: moment.showEndTimeInLiveActivity,
            notifyTwentyFourHours: moment.notifyTwentyFourHours,
            notifyOneHour: moment.notifyOneHour,
            notifyTenMinutes: moment.notifyTenMinutes
        )
        withAnimation(.spring(response: 0.3)) {
            modelContext.insert(newMoment)
        }
    }
    
    private func delete(_ moment: Moment) {
        // Cancel notifications
        Task {
            await NotificationManager.shared.removeNotifications(for: moment)
        }
        
        // End Live Activity
        Task {
            await LiveActivityManager.shared.endActivity(for: moment)
        }
        
        modelContext.delete(moment)
        
        // Save deletion to shared container
        try? modelContext.save()
        
        // Check remaining moments for Live Activities
        Task {
            LiveActivityManager.shared.checkAndManageActivities(for: allMoments.filter { $0.id != moment.id })
        }
        
        // Reload widgets after deleting moment
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    MomentsBoardView()
        .modelContainer(for: Moment.self, inMemory: true)
}
