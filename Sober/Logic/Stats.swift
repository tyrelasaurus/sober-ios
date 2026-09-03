import Foundation

/// Full stats summary, mirroring calc.js's computeStats() — the single
/// source of truth consumed by every screen.
struct Stats: Equatable {
    var streakDays: Int = 0
    var streakStartDate: String?
    var longestStreakDays: Int = 0
    var lifetimeSoberDays: Int = 0
    var relapses: Int = 0
    var moneySavedStreak: Double = 0
    var moneySavedLifetime: Double = 0
    var drinksAvoidedStreak: Double = 0
    var drinksAvoidedLifetime: Double = 0
    var dailySavingsRate: Double = 0
    var milestones: [Milestone] = []
    var nextMilestone: Milestone?
    var bestMilestones: [Milestone] = []
    var bestNextMilestone: Milestone?
    var trackPositionCurrent: Double = 0
    var trackPositionBest: Double = 0
    var avgMood7: Double?
    var avgSleep7: Double?
    var avgCraving7: Double?
    var insights: InsightsSummary = InsightsSummary()
    var weightStats: WeightStats = WeightStats()
}

enum StatsEngine {
    /// Rolling average of a numeric field over the last N days of check-ins.
    static func rollingAverage(_ checkins: [CheckIn], days: Int, now: Date = Date(), _ valueOf: (CheckIn) -> Double?) -> Double? {
        let cutoff = now.addingTimeInterval(-Double(days) * 86400)
        let relevant = checkins.compactMap { c -> Double? in
            let d = DateUtils.parseDate(c.date)
            guard d >= cutoff else { return nil }
            return valueOf(c)
        }
        guard !relevant.isEmpty else { return nil }
        return relevant.reduce(0, +) / Double(relevant.count)
    }

    static func compute(_ data: AppData, now: Date = Date()) -> Stats {
        let settings = data.settings
        let periods = data.periods
        let streakDays = Streaks.currentStreakDays(periods, now: now)
        let current = Streaks.currentPeriod(periods)
        let lifetimeDays = Streaks.totalSoberDays(periods, now: now)
        let longestDays = Streaks.longestStreakDays(periods, now: now)

        var stats = Stats()
        stats.streakDays = streakDays
        stats.streakStartDate = current?.startDate
        stats.longestStreakDays = longestDays
        stats.lifetimeSoberDays = lifetimeDays
        stats.relapses = Streaks.numRelapses(periods)
        stats.moneySavedStreak = Money.moneySavedForDays(streakDays, settings.moneyModel)
        stats.moneySavedLifetime = Money.moneySavedForDays(lifetimeDays, settings.moneyModel)
        stats.drinksAvoidedStreak = Money.drinksAvoidedForDays(streakDays, settings.moneyModel)
        stats.drinksAvoidedLifetime = Money.drinksAvoidedForDays(lifetimeDays, settings.moneyModel)
        stats.dailySavingsRate = Money.dailySavingsRate(settings.moneyModel)
        stats.milestones = Milestones.status(for: streakDays)
        stats.nextMilestone = Milestones.next(for: streakDays)
        // "Best-ever" milestones are scoped to the longest single streak, not
        // the current one — a relapse resets the current streak/milestones,
        // but the farthest you've ever gotten is a permanent record.
        stats.bestMilestones = Milestones.status(for: longestDays)
        stats.bestNextMilestone = Milestones.next(for: longestDays)
        stats.trackPositionCurrent = Milestones.trackPosition(streakDays)
        stats.trackPositionBest = Milestones.trackPosition(longestDays)
        stats.avgMood7 = rollingAverage(data.checkins, days: 7, now: now) { $0.mood.map(Double.init) }
        stats.avgSleep7 = rollingAverage(data.checkins, days: 7, now: now) { $0.sleepHours }
        stats.avgCraving7 = rollingAverage(data.checkins, days: 7, now: now) { $0.craving }
        stats.insights = Insights.compute(data)
        stats.weightStats = WeightLogic.stats(data.weighIns, now: now)
        return stats
    }
}
