import Foundation

/// Streak/period math — direct port of the period-related functions in calc.js.
enum Streaks {
    /// The currently-active period (endDate == nil), or nil.
    static func currentPeriod(_ periods: [Period]) -> Period? {
        periods.first { $0.endDate == nil }
    }

    /// Days elapsed in the current streak, as of `now`. Day 0 = start date.
    static func currentStreakDays(_ periods: [Period], now: Date = Date()) -> Int {
        guard let current = currentPeriod(periods) else { return 0 }
        let days = DateUtils.daysBetween(current.startDate, DateUtils.todayStr(now))
        return max(0, days)
    }

    /// Longest streak (in days) across all periods, closed or current.
    static func longestStreakDays(_ periods: [Period], now: Date = Date()) -> Int {
        guard !periods.isEmpty else { return 0 }
        var longest = 0
        for p in periods {
            let end = p.endDate ?? DateUtils.todayStr(now)
            let len = max(0, DateUtils.daysBetween(p.startDate, end))
            if len > longest { longest = len }
        }
        return longest
    }

    /// Sum of all sober days across every period (lifetime total).
    static func totalSoberDays(_ periods: [Period], now: Date = Date()) -> Int {
        guard !periods.isEmpty else { return 0 }
        var total = 0
        for p in periods {
            let end = p.endDate ?? DateUtils.todayStr(now)
            total += max(0, DateUtils.daysBetween(p.startDate, end))
        }
        return total
    }

    static func numRelapses(_ periods: [Period]) -> Int {
        periods.filter { $0.endDate != nil }.count
    }

    /// Start a fresh streak (first launch / onboarding). Defensively closes
    /// any dangling open period first.
    static func startPeriod(_ periods: [Period], startDateStr: String) -> [Period] {
        var list = periods.map { p -> Period in
            var p = p
            if p.endDate == nil {
                p.endDate = startDateStr
                p.endReason = "restarted"
            }
            return p
        }
        list.append(Period(id: makeId(), startDate: startDateStr, endDate: nil, endReason: nil))
        return list
    }

    /// Records a relapse: closes the current period today and starts a new
    /// one today. `triggers`/`note` are attached to the period that just
    /// closed, not the fresh one.
    static func recordRelapse(_ periods: [Period], dateStr: String, triggers: [String] = [], note: String = "") -> [Period] {
        var list = periods.map { p -> Period in
            var p = p
            if p.endDate == nil {
                p.endDate = dateStr
                p.endReason = "relapse"
                p.triggers = triggers
                p.note = note
            }
            return p
        }
        list.append(Period(id: makeId(), startDate: dateStr, endDate: nil, endReason: nil))
        return list
    }
}
