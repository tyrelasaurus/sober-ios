import SwiftUI
import Charts

struct SleepHealthView: View {
    @EnvironmentObject var store: Store
    @State private var showCheckIn = false
    @State private var editDate: String?

    private var last30: [CheckIn] {
        let cutoff = Date().addingTimeInterval(-30 * 86400)
        return store.data.checkins.filter { DateUtils.parseDate($0.date) >= cutoff }
    }

    private var last14: [CheckIn] {
        let cutoff = Date().addingTimeInterval(-14 * 86400)
        return store.data.checkins.filter { DateUtils.parseDate($0.date) >= cutoff }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgApp.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        statGrid
                        sleepChart
                        cravingChart
                        recentCheckIns
                    }
                    .padding()
                }
            }
            .foregroundStyle(Theme.textPrimary)
            .navigationTitle("Sleep & Health")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Log Check-In") { showCheckIn = true }
                }
            }
            .sheet(isPresented: $showCheckIn) {
                CheckInFormView(date: DateUtils.todayStr()).environmentObject(store)
            }
            .sheet(item: Binding(
                get: { editDate.map { IdentifiableString(value: $0) } },
                set: { editDate = $0?.value }
            )) { wrapped in
                CheckInFormView(date: wrapped.value).environmentObject(store)
            }
        }
    }

    private var statGrid: some View {
        let avgSleep = average(last14.compactMap { $0.sleepHours })
        let avgCraving = average(last14.compactMap { $0.craving })
        let ateWellPct = percentTrue(last14.map { $0.ateWell })
        let exercisedPct = percentTrue(last14.map { $0.exercised })
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(icon: "😴", value: avgSleep.map { String(format: "%.1f hrs", $0) } ?? "—", caption: "Avg Sleep (14d)")
            StatTile(icon: "🍷", value: avgCraving.map { String(format: "%.1f/10", $0) } ?? "—", caption: "Avg Craving (14d)")
            StatTile(icon: "🥗", value: "\(ateWellPct)%", caption: "Ate Well (14d)")
            StatTile(icon: "🏃", value: "\(exercisedPct)%", caption: "Exercised (14d)")
        }
    }

    private var sleepChart: some View {
        SectionCard(title: "Sleep — last 30 days") {
            let points = last30.compactMap { c -> (String, Double)? in c.sleepHours.map { (c.date, $0) } }
            if points.isEmpty {
                Text("No sleep logged yet.").font(.caption).foregroundStyle(Theme.textTertiary)
            } else {
                Chart(points, id: \.0) { point in
                    BarMark(x: .value("Date", point.0), y: .value("Hours", point.1)).foregroundStyle(Theme.accent2)
                }
                .chartXAxis(.hidden)
                .frame(height: 120)
            }
        }
    }

    private var cravingChart: some View {
        SectionCard(title: "Cravings — last 30 days", subtitle: "Self-rated intensity, 0 (none) – 10 (intense)") {
            let points = last30.compactMap { c -> (String, Double)? in c.craving.map { (c.date, $0) } }
            if points.isEmpty {
                Text("No cravings logged yet.").font(.caption).foregroundStyle(Theme.textTertiary)
            } else {
                Chart(points, id: \.0) { point in
                    LineMark(x: .value("Date", point.0), y: .value("Craving", point.1)).foregroundStyle(Theme.gold)
                }
                .chartYScale(domain: 0...10)
                .chartXAxis(.hidden)
                .frame(height: 120)
            }
        }
    }

    private var recentCheckIns: some View {
        SectionCard(title: "Recent check-ins", subtitle: "Last 20 logged") {
            VStack(spacing: 0) {
                ForEach(store.data.checkins.suffix(20).reversed()) { c in
                    Button { editDate = c.date } label: {
                        HStack {
                            Text(Fmt.relativeDay(c.date)).font(.caption.bold())
                            Text(Fmt.moodEmoji(c.mood))
                            if let sleep = c.sleepHours { Text("\(Fmt.num1(sleep)) hrs sleep").font(.caption2) }
                            Spacer()
                            if c.ateWell == true { Text("🥗").font(.caption) }
                            if c.exercised == true { Text("🏃").font(.caption) }
                        }
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.vertical, 6)
                    }
                    Divider().background(Theme.border)
                }
            }
        }
    }

    private func average(_ nums: [Double]) -> Double? {
        nums.isEmpty ? nil : nums.reduce(0, +) / Double(nums.count)
    }

    private func percentTrue(_ bools: [Bool?]) -> Int {
        let known = bools.compactMap { $0 }
        guard !known.isEmpty else { return 0 }
        return Int((Double(known.filter { $0 }.count) / Double(known.count) * 100).rounded())
    }
}

private struct IdentifiableString: Identifiable {
    let value: String
    var id: String { value }
}
