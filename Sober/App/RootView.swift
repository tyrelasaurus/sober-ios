import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        if store.data.onboarded {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            OverviewView()
                .tabItem { Label("Overview", systemImage: "square.grid.2x2") }
            JournalView()
                .tabItem { Label("Journal", systemImage: "book") }
            SleepHealthView()
                .tabItem { Label("Sleep & Health", systemImage: "heart") }
            CalendarScreenView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar") }
            MilestonesView()
                .tabItem { Label("Milestones", systemImage: "flag") }
            WeightView()
                .tabItem { Label("Weight", systemImage: "gauge") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
