import SwiftUI

struct StatTile: View {
    let icon: String
    let value: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(icon).font(.title3)
            Text(value).font(.title2.bold()).foregroundStyle(Theme.textPrimary)
            Text(caption).font(.caption).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).foregroundStyle(Theme.textPrimary)
            if let subtitle {
                Text(subtitle).font(.caption).foregroundStyle(Theme.textSecondary)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct CompareCardView: View {
    let title: String
    let subtitle: String
    let compare: GroupComparison?
    let maxScale: Double

    var body: some View {
        SectionCard(title: title, subtitle: subtitle) {
            if let compare {
                VStack(spacing: 10) {
                    CompareRow(label: compare.aLabel, avg: compare.aAvg, count: compare.aCount, maxScale: maxScale, color: Theme.gold)
                    CompareRow(label: compare.bLabel, avg: compare.bAvg, count: compare.bCount, maxScale: maxScale, color: Theme.accent2)
                }
            } else {
                Text("Not enough data yet — keep logging both together to unlock this.")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.top, 4)
            }
        }
    }
}

private struct CompareRow: View {
    let label: String
    let avg: Double
    let count: Int
    let maxScale: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.caption).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(count) day\(count == 1 ? "" : "s")").font(.caption2).foregroundStyle(Theme.textTertiary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.card)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * Fmt.clamp(avg / maxScale, 0.04, 1))
                }
            }
            .frame(height: 8)
            Text(Fmt.num1(avg)).font(.caption2).foregroundStyle(Theme.textSecondary)
        }
    }
}

struct BarListView: View {
    struct Row: Identifiable {
        let id: String
        let label: String
        let emoji: String
        let value: Double
        let display: String
    }

    let rows: [Row]
    let maxVal: Double
    let emptyText: String

    var body: some View {
        if rows.isEmpty {
            Text(emptyText).font(.caption).foregroundStyle(Theme.textTertiary)
        } else {
            VStack(spacing: 10) {
                ForEach(rows) { row in
                    HStack {
                        Text("\(row.emoji) \(row.label)").font(.caption).foregroundStyle(Theme.textPrimary)
                        Spacer()
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Theme.card)
                                Capsule().fill(Theme.accent).frame(width: geo.size.width * Fmt.clamp(row.value / maxVal, 0.04, 1))
                            }
                        }
                        .frame(width: 120, height: 8)
                        Text(row.display).font(.caption2).foregroundStyle(Theme.textSecondary).frame(width: 30, alignment: .trailing)
                    }
                }
            }
        }
    }
}
