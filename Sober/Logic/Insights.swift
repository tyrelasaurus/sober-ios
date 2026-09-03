import Foundation

struct TriggerTag: Identifiable, Equatable {
    let id: String
    let label: String
    let emoji: String
}

struct TriggerCount: Identifiable, Equatable {
    let id: String
    let label: String
    let emoji: String
    let count: Int
}

struct TriggerCraving: Identifiable, Equatable {
    let id: String
    let label: String
    let emoji: String
    let count: Int
    let avgCraving: Double
}

/// Result of comparing an average value between two groups of check-ins.
/// Mirrors calc.js's compareCheckinGroups return shape.
struct GroupComparison: Equatable {
    let aLabel: String
    let bLabel: String
    let aAvg: Double
    let bAvg: Double
    let aCount: Int
    let bCount: Int
}

struct InsightsSummary: Equatable {
    var triggerFrequency: [TriggerCount] = []
    var cravingByTrigger: [TriggerCraving] = []
    var relapseTriggers: [TriggerCount] = []
    var sleepCraving: GroupComparison?
    var sleepMood: GroupComparison?
    var exerciseDurationMood: GroupComparison?
    var exerciseDurationCraving: GroupComparison?
    var exerciseIntensityMood: GroupComparison?
    var exerciseIntensityCraving: GroupComparison?
    var totalCheckins: Int = 0
    var totalRelapses: Int = 0
}

enum Insights {
    /// Fixed set of trigger tags a user can attach to a check-in or a slip.
    static let triggerTags: [TriggerTag] = [
        TriggerTag(id: "stress", label: "Stress", emoji: "😣"),
        TriggerTag(id: "social", label: "Social pressure", emoji: "🍻"),
        TriggerTag(id: "boredom", label: "Boredom", emoji: "🥱"),
        TriggerTag(id: "poor_sleep", label: "Poor sleep", emoji: "😴"),
        TriggerTag(id: "conflict", label: "Conflict", emoji: "💥"),
        TriggerTag(id: "work", label: "Work", emoji: "💼"),
        TriggerTag(id: "loneliness", label: "Loneliness", emoji: "🙁"),
        TriggerTag(id: "celebration", label: "Celebration", emoji: "🎉"),
        TriggerTag(id: "access", label: "Easy access", emoji: "🍺"),
    ]

    /// Below this many data points in a bucket/group, an average is more
    /// noise than signal, so comparisons hide themselves rather than mislead.
    static let minSamples = 2

    static func average(_ nums: [Double]) -> Double? {
        guard !nums.isEmpty else { return nil }
        return nums.reduce(0, +) / Double(nums.count)
    }

    static func median(_ nums: [Double]) -> Double? {
        guard !nums.isEmpty else { return nil }
        let sorted = nums.sorted()
        let mid = sorted.count / 2
        return sorted.count % 2 == 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }

    /// Compares the average of a value field between two groups of
    /// check-ins, where `groupFn` returns "a", "b", or nil to exclude a
    /// check-in from both. Returns nil (rather than a misleading average) if
    /// either group has fewer than `minSamples` data points.
    static func compareCheckinGroups(
        _ checkins: [CheckIn], value valueOf: (CheckIn) -> Double?,
        group groupFn: (CheckIn) -> String?, labels: (a: String, b: String)
    ) -> GroupComparison? {
        var a: [Double] = []
        var b: [Double] = []
        for c in checkins {
            guard let v = valueOf(c) else { continue }
            switch groupFn(c) {
            case "a": a.append(v)
            case "b": b.append(v)
            default: continue
            }
        }
        guard a.count >= minSamples, b.count >= minSamples,
              let aAvg = average(a), let bAvg = average(b) else { return nil }
        return GroupComparison(aLabel: labels.a, bLabel: labels.b, aAvg: aAvg, bAvg: bAvg, aCount: a.count, bCount: b.count)
    }

    static func sleepCorrelation(_ checkins: [CheckIn], _ valueOf: @escaping (CheckIn) -> Double?) -> GroupComparison? {
        compareCheckinGroups(
            checkins, value: valueOf,
            group: { c in
                guard let h = c.sleepHours else { return nil }
                return h < 6 ? "a" : "b"
            },
            labels: ("Under 6 hrs sleep", "6+ hrs sleep")
        )
    }

    /// Splits at the median of the user's own logged durations rather than a
    /// fixed cutoff — a fixed number means nothing across different
    /// people's baselines. The median self-calibrates, so it only reports
    /// "not enough data" when durations genuinely don't vary.
    static func exerciseDurationCorrelation(_ checkins: [CheckIn], _ valueOf: @escaping (CheckIn) -> Double?) -> GroupComparison? {
        let minutesValues = checkins.compactMap { c -> Double? in
            guard c.exerciseMinutes != nil, valueOf(c) != nil else { return nil }
            return c.exerciseMinutes
        }
        guard let threshold = median(minutesValues) else { return nil }
        return compareCheckinGroups(
            checkins, value: valueOf,
            group: { c in
                guard let m = c.exerciseMinutes else { return nil }
                return m < threshold ? "a" : "b"
            },
            labels: ("Under \(Int(threshold.rounded())) min", "\(Int(threshold.rounded()))+ min")
        )
    }

    /// Light activity (e.g. a walk) vs. moderate/vigorous.
    static func exerciseIntensityCorrelation(_ checkins: [CheckIn], _ valueOf: @escaping (CheckIn) -> Double?) -> GroupComparison? {
        compareCheckinGroups(
            checkins, value: valueOf,
            group: { c in
                switch c.exerciseIntensity {
                case "light": return "a"
                case "moderate", "vigorous": return "b"
                default: return nil
                }
            },
            labels: ("Light activity", "Moderate/vigorous")
        )
    }

    static func triggerTagCounts(_ triggerLists: [[String]]) -> [TriggerCount] {
        var counts: [String: Int] = [:]
        for triggers in triggerLists {
            for id in triggers { counts[id, default: 0] += 1 }
        }
        return triggerTags
            .map { TriggerCount(id: $0.id, label: $0.label, emoji: $0.emoji, count: counts[$0.id] ?? 0) }
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }
    }

    static func avgCravingByTrigger(_ checkins: [CheckIn]) -> [TriggerCraving] {
        var byTag: [String: [Double]] = [:]
        for c in checkins {
            guard let craving = c.craving else { continue }
            for id in c.triggers { byTag[id, default: []].append(craving) }
        }
        return triggerTags.compactMap { tag -> TriggerCraving? in
            let vals = byTag[tag.id] ?? []
            guard vals.count >= minSamples, let avg = average(vals) else { return nil }
            return TriggerCraving(id: tag.id, label: tag.label, emoji: tag.emoji, count: vals.count, avgCraving: avg)
        }.sorted { $0.avgCraving > $1.avgCraving }
    }

    static func compute(_ data: AppData) -> InsightsSummary {
        let checkins = data.checkins
        let relapsePeriods = data.periods.filter { $0.endReason == "relapse" }

        var summary = InsightsSummary()
        summary.triggerFrequency = triggerTagCounts(checkins.map { $0.triggers } + relapsePeriods.map { $0.triggers ?? [] })
        summary.cravingByTrigger = avgCravingByTrigger(checkins)
        summary.relapseTriggers = triggerTagCounts(relapsePeriods.map { $0.triggers ?? [] })
        summary.sleepCraving = sleepCorrelation(checkins) { $0.craving }
        summary.sleepMood = sleepCorrelation(checkins) { $0.mood.map(Double.init) }
        summary.exerciseDurationMood = exerciseDurationCorrelation(checkins) { $0.mood.map(Double.init) }
        summary.exerciseDurationCraving = exerciseDurationCorrelation(checkins) { $0.craving }
        summary.exerciseIntensityMood = exerciseIntensityCorrelation(checkins) { $0.mood.map(Double.init) }
        summary.exerciseIntensityCraving = exerciseIntensityCorrelation(checkins) { $0.craving }
        summary.totalCheckins = checkins.count
        summary.totalRelapses = relapsePeriods.count
        return summary
    }
}
