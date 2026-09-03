import Foundation

/// Date helpers operating on "YYYY-MM-DD" local-calendar-day strings, mirroring
/// calc.js's date handling exactly (local midnight, not UTC) so streak/day math
/// matches the Mac app.
enum DateUtils {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        return cal
    }()

    /// Parses a "YYYY-MM-DD" string as a local-midnight Date.
    static func parseDate(_ dateStr: String) -> Date {
        let parts = dateStr.prefix(10).split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return Date() }
        var comps = DateComponents()
        comps.year = parts[0]
        comps.month = parts[1]
        comps.day = parts[2]
        return calendar.date(from: comps) ?? Date()
    }

    static func todayStr(_ now: Date = Date()) -> String {
        dateStr(from: now)
    }

    static func dateStr(from date: Date) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }

    /// Whole days between two "YYYY-MM-DD" strings (end - start).
    static func daysBetween(_ startDateStr: String, _ endDateStr: String) -> Int {
        let start = parseDate(startDateStr)
        let end = parseDate(endDateStr)
        let seconds = end.timeIntervalSince(start)
        return Int((seconds / 86400).rounded())
    }
}
