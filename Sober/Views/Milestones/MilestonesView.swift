import SwiftUI

struct MilestonesView: View {
    @EnvironmentObject var store: Store

    private var stats: Stats { store.stats }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgApp.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        summaryCards
                        track
                        list
                    }
                    .padding()
                }
            }
            .foregroundStyle(Theme.textPrimary)
            .navigationTitle("Milestones")
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current streak").font(.caption).foregroundStyle(Theme.textSecondary)
                Text("\(stats.streakDays) Days").font(.title3.bold())
                if let next = stats.nextMilestone {
                    Text("\(max(0, next.days - stats.streakDays)) day(s) until \"\(next.title)\"").font(.caption2).foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()

            VStack(alignment: .leading, spacing: 4) {
                Text("🏆 Farthest ever reached").font(.caption).foregroundStyle(Theme.textSecondary)
                Text("\(stats.longestStreakDays) Days").font(.title3.bold())
                if let next = stats.bestNextMilestone {
                    Text("\(max(0, next.days - stats.longestStreakDays)) day(s) from \"\(next.title)\" at your best").font(.caption2).foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }

    private var track: some View {
        SectionCard(title: "Your milestone track", subtitle: "Gold marks the farthest you've ever reached — it never resets, even after a slip. The blue dot is your current streak, right now.") {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.card).frame(height: 6)
                    Capsule().fill(Theme.gold).frame(width: geo.size.width * stats.trackPositionBest / 100, height: 6)
                    Circle().fill(Theme.accent).frame(width: 12, height: 12)
                        .offset(x: geo.size.width * stats.trackPositionCurrent / 100 - 6)
                    Text("🏆").offset(x: geo.size.width * stats.trackPositionBest / 100 - 8, y: -16)
                }
            }
            .frame(height: 30)
            .padding(.top, 8)
        }
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(Milestones.all) { m in
                let currentReached = stats.streakDays >= m.days
                let bestReached = stats.longestStreakDays >= m.days
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(currentReached ? Theme.accent2 : (bestReached ? Theme.gold : Theme.card))
                        .frame(width: 10, height: 10)
                        .padding(.top, 4)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(m.title).font(.subheadline.bold())
                            if currentReached {
                                badge("Reached", color: Theme.accent2)
                            } else if bestReached {
                                badge("🏆 Personal best", color: Theme.gold)
                            }
                        }
                        Text(m.text).font(.caption).foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(.vertical, 8)
                Divider().background(Theme.border)
            }
        }
        .cardStyle()
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 8).padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
