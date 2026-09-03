import SwiftUI

struct CalendarScreenView: View {
    @EnvironmentObject var store: Store
    @State private var visibleMonth = Date()
    @State private var editDate: String?

    private var byDate: [String: CheckIn] {
        Dictionary(uniqueKeysWithValues: store.data.checkins.map { ($0.date, $0) })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgApp.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        monthHeader
                        calendarGrid
                        notesList
                    }
                    .padding()
                }
            }
            .foregroundStyle(Theme.textPrimary)
            .navigationTitle("Calendar")
            .sheet(item: Binding(
                get: { editDate.map { IdWrap(value: $0) } },
                set: { editDate = $0?.value }
            )) { wrapped in
                CheckInFormView(date: wrapped.value).environmentObject(store)
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(monthTitle).font(.headline)
            Spacer()
            Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
        }
        .foregroundStyle(Theme.textPrimary)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: visibleMonth)
    }

    private func shiftMonth(_ delta: Int) {
        visibleMonth = DateUtils.calendar.date(byAdding: .month, value: delta, to: visibleMonth) ?? visibleMonth
    }

    private var daysInMonth: [Date?] {
        let cal = DateUtils.calendar
        guard let range = cal.range(of: .day, in: .month, for: visibleMonth),
              let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: visibleMonth))
        else { return [] }
        let weekday = cal.component(.weekday, from: firstOfMonth) - 1
        var days: [Date?] = Array(repeating: nil, count: weekday)
        for day in range {
            if let d = cal.date(byAdding: .day, value: day - 1, to: firstOfMonth) { days.append(d) }
        }
        return days
    }

    private var calendarGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return VStack {
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { d in
                    Text(d).font(.caption2).foregroundStyle(Theme.textTertiary).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date {
                        let dateStr = DateUtils.dateStr(from: date)
                        let checkin = byDate[dateStr]
                        Button { editDate = dateStr } label: {
                            VStack(spacing: 2) {
                                Text("\(DateUtils.calendar.component(.day, from: date))").font(.caption2)
                                if checkin != nil {
                                    Circle().fill(Theme.accent).frame(width: 4, height: 4)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(moodColor(checkin?.mood))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .foregroundStyle(Theme.textPrimary)
                    } else {
                        Color.clear.frame(minHeight: 36)
                    }
                }
            }
        }
        .cardStyle()
    }

    private func moodColor(_ mood: Int?) -> Color {
        guard let mood else { return Theme.card }
        return Theme.accent2.opacity(0.25 + Double(mood) / 5.0 * 0.5)
    }

    private var notesList: some View {
        let cal = DateUtils.calendar
        let monthEntries = store.data.checkins
            .filter { !( $0.note ?? "").isEmpty }
            .filter { c in
                let d = DateUtils.parseDate(c.date)
                return cal.isDate(d, equalTo: visibleMonth, toGranularity: .month)
            }
            .sorted { $0.date > $1.date }

        return SectionCard(title: "Notes — \(monthTitle)", subtitle: "Every note you've logged this month, in one place") {
            if monthEntries.isEmpty {
                Text("No notes this month.").font(.caption).foregroundStyle(Theme.textTertiary)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(monthEntries) { c in
                        Button { editDate = c.date } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(Fmt.dateMedium(c.date)).font(.caption.bold())
                                    Text(Fmt.moodEmoji(c.mood))
                                }
                                Text(c.note ?? "").font(.caption).foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .foregroundStyle(Theme.textPrimary)
                    }
                }
            }
        }
    }
}

private struct IdWrap: Identifiable {
    let value: String
    var id: String { value }
}
