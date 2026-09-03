import SwiftUI
import Charts

struct OverviewView: View {
    @EnvironmentObject var store: Store
    @State private var showCheckIn = false
    @State private var showSlip = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgApp.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        streakCard
                        statGrid
                        moodChart
                        sleepChart
                        checkInActivity
                    }
                    .padding()
                }
            }
            .foregroundStyle(Theme.textPrimary)
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Full Check-In") { showCheckIn = true }
                    Button("I had a drink") { showSlip = true }
                        .foregroundStyle(Theme.danger)
                }
            }
            .sheet(isPresented: $showCheckIn) {
                CheckInFormView(date: DateUtils.todayStr()).environmentObject(store)
            }
            .sheet(isPresented: $showSlip) {
                SlipConfirmView().environmentObject(store)
            }
        }
    }

    private var stats: Stats { store.stats }

    private var streakCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Theme.border, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: min(1, stats.trackPositionCurrent / 100))
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack {
                    Text("\(stats.streakDays)").font(.title.bold())
                    Text("DAYS").font(.caption2).foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(width: 90, height: 90)

            VStack(alignment: .leading, spacing: 4) {
                Text(stats.streakStartDate != nil ? "Sober since \(Fmt.dateShort(stats.streakStartDate))" : "Not started yet")
                    .font(.headline)
                if let next = stats.nextMilestone {
                    let remaining = max(0, next.days - stats.streakDays)
                    Text("\(next.title) in \(remaining) day\(remaining == 1 ? "" : "s") — \(next.text)")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Text("All milestones reached. Incredible work.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .cardStyle()
    }

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(icon: "💰", value: Money.formatMoney(stats.moneySavedLifetime, symbol: store.data.settings.currencySymbol), caption: "Money Saved")
            StatTile(icon: "🍺", value: Fmt.num1(stats.drinksAvoidedLifetime), caption: "Drinks Avoided")
            StatTile(icon: "🏆", value: "\(stats.longestStreakDays) Days", caption: "Longest Streak")
            StatTile(icon: "📅", value: "\(stats.lifetimeSoberDays)", caption: "Total Days Sober")
        }
    }

    private var moodPoints: [(date: String, mood: Double)] {
        let cutoff = Date().addingTimeInterval(-30 * 86400)
        return store.data.checkins
            .filter { DateUtils.parseDate($0.date) >= cutoff }
            .compactMap { c in c.mood.map { (c.date, Double($0)) } }
    }

    private var moodChart: some View {
        SectionCard(title: "Mood — last 30 days") {
            if moodPoints.isEmpty {
                Text("No mood check-ins yet.").font(.caption).foregroundStyle(Theme.textTertiary)
            } else {
                Chart(moodPoints, id: \.date) { point in
                    LineMark(x: .value("Date", point.date), y: .value("Mood", point.mood))
                        .foregroundStyle(Theme.accent)
                    PointMark(x: .value("Date", point.date), y: .value("Mood", point.mood))
                        .foregroundStyle(Theme.accent)
                }
                .chartYScale(domain: 1...5)
                .chartXAxis(.hidden)
                .frame(height: 120)
            }
        }
    }

    private var sleepPoints: [(date: String, hours: Double)] {
        let cutoff = Date().addingTimeInterval(-14 * 86400)
        return store.data.checkins
            .filter { DateUtils.parseDate($0.date) >= cutoff }
            .compactMap { c in c.sleepHours.map { (c.date, $0) } }
    }

    private var sleepChart: some View {
        SectionCard(title: "Sleep — last 14 days") {
            if sleepPoints.isEmpty {
                Text("No sleep check-ins yet.").font(.caption).foregroundStyle(Theme.textTertiary)
            } else {
                Chart(sleepPoints, id: \.date) { point in
                    BarMark(x: .value("Date", point.date), y: .value("Hours", point.hours))
                        .foregroundStyle(Theme.accent2)
                }
                .chartXAxis(.hidden)
                .frame(height: 120)
            }
        }
    }

    private var checkInActivity: some View {
        let last35Days = (0..<35).reversed().map { i -> String in
            DateUtils.todayStr(Date().addingTimeInterval(-Double(i) * 86400))
        }
        let byDate = Dictionary(uniqueKeysWithValues: store.data.checkins.map { ($0.date, $0) })
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return SectionCard(title: "Check-in activity", subtitle: "Each square is a day you logged a check-in — the darker, the better your mood that day.") {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(last35Days, id: \.self) { day in
                    let mood = byDate[day]?.mood
                    RoundedRectangle(cornerRadius: 3)
                        .fill(moodColor(mood))
                        .frame(height: 16)
                }
            }
        }
    }

    private func moodColor(_ mood: Int?) -> Color {
        guard let mood else { return Theme.card }
        let intensity = Double(mood) / 5.0
        return Theme.accent2.opacity(0.25 + intensity * 0.6)
    }
}

struct SlipConfirmView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var triggers: [String] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgApp.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    Text("This closes your current streak and starts a new one today. Your past streak stays in your history — setbacks are part of the process, not a reason to give up.")
                        .font(.callout)
                        .foregroundStyle(Theme.textSecondary)
                    Text("What led to it? (optional)").font(.caption).foregroundStyle(Theme.textSecondary)
                    TriggerChips(selected: $triggers)
                    Spacer()
                    Button("Log It & Restart", role: .destructive) {
                        store.recordRelapse(triggers: triggers)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.danger)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .foregroundStyle(Theme.textPrimary)
            .navigationTitle("Log a Drink?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}
