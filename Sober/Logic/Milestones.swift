import Foundation

struct Milestone: Identifiable, Equatable {
    let id: String
    let days: Int
    let title: String
    let text: String
    var achieved: Bool = false
}

enum Milestones {
    static let all: [Milestone] = [
        Milestone(id: "h24", days: 1, title: "24 Hours", text: "Alcohol has cleared your system. Blood sugar and blood pressure typically begin to stabilize."),
        Milestone(id: "d3", days: 3, title: "3 Days", text: "Acute withdrawal symptoms usually peak and start to ease. Sleep may still be restless."),
        Milestone(id: "w1", days: 7, title: "1 Week", text: "Hydration and sleep quality often improve. Many people notice a boost in daytime energy."),
        Milestone(id: "w2", days: 14, title: "2 Weeks", text: "Liver inflammation often starts to reduce. Skin, digestion, and focus can begin to improve."),
        Milestone(id: "m1", days: 30, title: "1 Month", text: "Sleep patterns often normalize. Mood and concentration commonly improve, and savings really start to add up."),
        Milestone(id: "m3", days: 90, title: "3 Months", text: "Brain chemistry continues to rebalance. Cravings often become less frequent and less intense."),
        Milestone(id: "m6", days: 180, title: "6 Months", text: "New coping habits are usually well established. Many people report sustained mood improvements."),
        Milestone(id: "y1", days: 365, title: "1 Year", text: "A major milestone — significantly reduced health risks and a well-established sober routine."),
        Milestone(id: "y2", days: 730, title: "2 Years", text: "Long-term recovery statistically becomes far more durable the longer a streak continues."),
    ]

    static func status(for streakDays: Int) -> [Milestone] {
        all.map { m in
            var m = m
            m.achieved = streakDays >= m.days
            return m
        }
    }

    static func next(for streakDays: Int) -> Milestone? {
        all.first { streakDays < $0.days }
    }

    /// Maps a day count to a 0-100 position along an evenly-spaced milestone
    /// track — each milestone gets an equal-width segment regardless of its
    /// actual day count, interpolating smoothly within whichever segment
    /// `days` falls in.
    static func trackPosition(_ days: Int) -> Double {
        let d = Double(max(0, days))
        let points = [0] + all.map { $0.days }
        let segments = points.count - 1
        for i in 0..<segments {
            let a = Double(points[i])
            let b = Double(points[i + 1])
            if d <= b {
                let frac = b > a ? (d - a) / (b - a) : 1
                return (Double(i) + frac) / Double(segments) * 100
            }
        }
        return 100
    }

    static func formatStreak(_ days: Int) -> String {
        if days <= 0 { return "Day 0" }
        if days == 1 { return "1 Day" }
        return "\(days) Days"
    }
}
