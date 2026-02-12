import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("defaultAccentColor") private var defaultAccentColor = "#007AFF"
    @State private var selectedTab = 0
    @State private var showingEditor = false
    @Environment(\.scenePhase) private var scenePhase
    @Query private var allMoments: [Moment]
    
    enum TabSelection: Hashable {
        case moments
        case add
        case settings
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Moments", systemImage: "calendar", value: 0) {
                MomentsBoardView()
            }
            
            Tab("Add", systemImage: "plus.circle.fill", value: 1, role: .search) {
                Color.clear
                    .toolbarBackground(Color(hex: defaultAccentColor) ?? .blue, for: .tabBar)
            }
            
            Tab("Settings", systemImage: "gear", value: 2) {
                SettingsView()
            }
        }
        .tint(Color(hex: defaultAccentColor) ?? .blue)
        .tabViewStyle(.tabBarOnly)
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 1 {
                // Intercept the add tab selection
                showingEditor = true
                // Reset to previous tab
                selectedTab = oldValue
            }
        }
        .sheet(isPresented: $showingEditor) {
            MomentEditorView()
        }
        .onAppear {
            configureTabBarAppearance()
            // Share moments with widgets on app launch
            WidgetDataManager.shared.shareMomentsWithWidgets(allMoments)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Refresh Live Activities when app becomes active
                LiveActivityManager.shared.checkAndManageActivities(for: allMoments)
                
                // Share data with widgets
                WidgetDataManager.shared.shareMomentsWithWidgets(allMoments)
            }
        }
        .onChange(of: allMoments) { _, newMoments in
            // Share updated moments with widgets whenever data changes
            WidgetDataManager.shared.shareMomentsWithWidgets(newMoments)
        }
    }
    
    private func configureTabBarAppearance() {
        // Customize the tab bar and search pod appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // Set the accent color for the search pod
        let accentUIColor = UIColor(Color(hex: defaultAccentColor) ?? .blue)
        
        // Configure inline appearance (affects the search pod)
        let inlineAppearance = UITabBarItemAppearance()
        inlineAppearance.normal.iconColor = accentUIColor
        inlineAppearance.selected.iconColor = accentUIColor
        inlineAppearance.normal.titleTextAttributes = [.foregroundColor: accentUIColor]
        inlineAppearance.selected.titleTextAttributes = [.foregroundColor: accentUIColor]
        
        appearance.inlineLayoutAppearance = inlineAppearance
        appearance.stackedLayoutAppearance = UITabBarItemAppearance()
        appearance.compactInlineLayoutAppearance = inlineAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = accentUIColor
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Moment.self, inMemory: true)
}
