import Foundation

struct WeightStats: Equatable {
    var count: Int = 0
    var firstWeighIn: WeighIn?
    var latestWeighIn: WeighIn?
    var weightChangeKg: Double?
    var daysSinceLastWeighIn: Int?
    var dueInDays: Int = 0
    var isDue: Bool = true
}

enum WeightLogic {
    static let lbPerKg = 2.2046226218
    static let weighInCadenceDays = 7

    static func kgToLb(_ kg: Double) -> Double { kg * lbPerKg }
    static func lbToKg(_ lb: Double) -> Double { lb / lbPerKg }

    static func sorted(_ weighIns: [WeighIn]) -> [WeighIn] {
        weighIns.sorted { $0.date < $1.date }
    }

    /// Summarizes weigh-in history: first/latest entries, net change since
    /// the first log (negative = loss), and days until the next weigh-in is
    /// "due" on a weekly cadence — never overdue-shaming, just a day count.
    static func stats(_ weighIns: [WeighIn], now: Date = Date()) -> WeightStats {
        let sortedIns = sorted(weighIns)
        let first = sortedIns.first
        let latest = sortedIns.last
        var changeKg: Double?
        if let f = first?.weightKg, let l = latest?.weightKg {
            changeKg = l - f
        }
        var daysSince: Int?
        if let latest {
            daysSince = latest.date.isEmpty ? nil : DateUtils.daysBetween(latest.date, DateUtils.todayStr(now))
        }
        let dueIn = daysSince == nil ? 0 : max(0, weighInCadenceDays - daysSince!)
        let isDue = daysSince == nil || daysSince! >= weighInCadenceDays
        return WeightStats(
            count: sortedIns.count, firstWeighIn: first, latestWeighIn: latest,
            weightChangeKg: changeKg, daysSinceLastWeighIn: daysSince, dueInDays: dueIn, isDue: isDue
        )
    }
}
