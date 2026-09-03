import Foundation

/// Display formatting helpers, mirroring src/renderer/shared/format.js.
enum Fmt {
    static func moodEmoji(_ score: Int?) -> String {
        guard let score else { return "😐" }
        switch score {
        case 1: return "😞"
        case 2: return "🙁"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😄"
        default: return "😐"
        }
    }

    static func num1(_ n: Double?) -> String {
        guard let n else { return "—" }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    static func clamp(_ n: Double, _ min: Double, _ max: Double) -> Double {
        Swift.min(max, Swift.max(min, n))
    }

    static func dateShort(_ dateStr: String?) -> String {
        guard let dateStr, !dateStr.isEmpty else { return "" }
        let date = DateUtils.parseDate(dateStr)
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d yyyy")
        return formatter.string(from: date)
    }

    static func dateLong(_ dateStr: String?) -> String {
        guard let dateStr, !dateStr.isEmpty else { return "" }
        let date = DateUtils.parseDate(dateStr)
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE MMMM d yyyy")
        return formatter.string(from: date)
    }

    static func dateMedium(_ dateStr: String?) -> String {
        guard let dateStr, !dateStr.isEmpty else { return "" }
        let date = DateUtils.parseDate(dateStr)
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE MMM d")
        return formatter.string(from: date)
    }

    static func relativeDay(_ dateStr: String) -> String {
        let today = DateUtils.todayStr()
        if dateStr == today { return "Today" }
        let yesterday = DateUtils.todayStr(Date().addingTimeInterval(-86400))
        if dateStr == yesterday { return "Yesterday" }
        return dateMedium(dateStr)
    }

    /// Converts a stored kg value to the display unit, rounded to 1 decimal.
    static func weightDisplay(_ kg: Double?, unit: WeightUnit) -> Double? {
        guard let kg else { return nil }
        let v = unit == .kg ? kg : WeightLogic.kgToLb(kg)
        return (v * 10).rounded() / 10
    }

    /// Converts a form input value (in the display unit) back to kg for storage.
    static func weightToKg(_ value: Double?, unit: WeightUnit) -> Double? {
        guard let value else { return nil }
        return unit == .kg ? value : WeightLogic.lbToKg(value)
    }
}
