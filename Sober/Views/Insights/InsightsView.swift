import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var store: Store

    private var insights: InsightsSummary { store.stats.insights }
    private var hasAnyData: Bool { insights.totalCheckins > 0 || insights.totalRelapses > 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgApp.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if hasAnyData {
                            body_
                        } else {
                            Text("Log a few check-ins — especially sleep and craving intensity — and this page will start surfacing real patterns: which triggers tend to spike your cravings, or whether a short night's sleep tracks with a rougher day. The more you log, the sharper it gets.")
                                .font(.callout)
                                .foregroundStyle(Theme.textSecondary)
                                .cardStyle()
                        }
                    }
                    .padding()
                }
            }
            .foregroundStyle(Theme.textPrimary)
            .navigationTitle("Insights")
        }
    }

    private var body_: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Patterns across your sleep, mood, cravings, and triggers — based on \(insights.totalCheckins) check-in\(insights.totalCheckins == 1 ? "" : "s") so far")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)

            CompareCardView(title: "Sleep & craving", subtitle: "Average craving intensity (0–10) by how much you slept", compare: insights.sleepCraving, maxScale: 10)
            CompareCardView(title: "Sleep & mood", subtitle: "Average mood (1–5) by how much you slept", compare: insights.sleepMood, maxScale: 5)
            CompareCardView(title: "Exercise duration & mood", subtitle: "Average mood (1–5) by how long you exercised", compare: insights.exerciseDurationMood, maxScale: 5)
            CompareCardView(title: "Exercise duration & craving", subtitle: "Average craving (0–10) by how long you exercised", compare: insights.exerciseDurationCraving, maxScale: 10)
            CompareCardView(title: "Exercise intensity & mood", subtitle: "Average mood (1–5) by how intense your exercise was", compare: insights.exerciseIntensityMood, maxScale: 5)
            CompareCardView(title: "Exercise intensity & craving", subtitle: "Average craving (0–10) by how intense your exercise was", compare: insights.exerciseIntensityCraving, maxScale: 10)

            SectionCard(title: "What's driving cravings", subtitle: "Average craving intensity on check-ins tagged with each trigger") {
                BarListView(
                    rows: insights.cravingByTrigger.map { .init(id: $0.id, label: $0.label, emoji: $0.emoji, value: $0.avgCraving, display: Fmt.num1($0.avgCraving)) },
                    maxVal: 10,
                    emptyText: "Trigger tags show up here once you've used them on a few check-ins."
                )
            }

            SectionCard(title: "Most logged triggers", subtitle: "How often each trigger tag has come up, across check-ins and slips") {
                let maxCount = max(1, insights.triggerFrequency.map { $0.count }.max() ?? 1)
                BarListView(
                    rows: insights.triggerFrequency.map { .init(id: $0.id, label: $0.label, emoji: $0.emoji, value: Double($0.count), display: "\($0.count)") },
                    maxVal: Double(maxCount),
                    emptyText: "Nothing tagged yet — trigger tags appear here once you start using them."
                )
            }

            if !insights.relapseTriggers.isEmpty {
                SectionCard(title: "What led to a slip", subtitle: "Trigger tags logged at the time of a relapse") {
                    let maxCount = max(1, insights.relapseTriggers.map { $0.count }.max() ?? 1)
                    BarListView(
                        rows: insights.relapseTriggers.map { .init(id: $0.id, label: $0.label, emoji: $0.emoji, value: Double($0.count), display: "\($0.count)") },
                        maxVal: Double(maxCount),
                        emptyText: ""
                    )
                }
            }
        }
    }
}
