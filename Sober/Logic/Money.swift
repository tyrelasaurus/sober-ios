import Foundation

/// Money-saved / drinks-avoided math — direct port of calc.js's money functions.
enum Money {
    static func clampPct(_ n: Double) -> Double {
        min(100, max(0, n))
    }

    /// Money saved per day, from the weekly-pattern model: paid days/week x
    /// how often you'd actually go out x typical spend per outing.
    static func dailySavingsRate(_ mm: MoneyModel) -> Double {
        let weeklySpend = mm.paidDaysPerWeek * (clampPct(mm.paidOutFrequencyPct) / 100) * mm.avgSpendPerOuting
        return weeklySpend / 7
    }

    /// Drinks avoided per day — includes free-access days, which have no
    /// cost but are still real drinks not had.
    static func dailyDrinksAvoidedRate(_ mm: MoneyModel) -> Double {
        let weeklyDrinks = mm.freeDaysPerWeek * mm.freeDrinksPerDay
            + mm.paidDaysPerWeek * (clampPct(mm.paidOutFrequencyPct) / 100) * mm.paidDrinksPerDay
        return weeklyDrinks / 7
    }

    static func moneySavedForDays(_ days: Int, _ mm: MoneyModel) -> Double {
        max(0, Double(days)) * dailySavingsRate(mm)
    }

    static func drinksAvoidedForDays(_ days: Int, _ mm: MoneyModel) -> Double {
        max(0, Double(days)) * dailyDrinksAvoidedRate(mm)
    }

    static func formatMoney(_ amount: Double, symbol: String = "$") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        let n = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return "\(symbol)\(n)"
    }

    static func formatMoneyPrecise(_ amount: Double, symbol: String = "$") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        let n = formatter.string(from: NSNumber(value: amount)) ?? "0.00"
        return "\(symbol)\(n)"
    }
}
