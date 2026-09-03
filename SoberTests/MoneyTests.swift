import XCTest
@testable import Sober

final class MoneyTests: XCTestCase {
    func testMoneySavedWithMoneyModelOnlyCountsPaidDaysAtActualGoOutFrequency() {
        // 3 paid days/week, 80% actual frequency, $16/outing -> weekly = 3*0.8*16 = 38.4, daily = 5.4857...
        let mm = MoneyModel(freeDaysPerWeek: 4, freeDrinksPerDay: 2, paidDaysPerWeek: 3, paidDrinksPerDay: 2, paidOutFrequencyPct: 80, avgSpendPerOuting: 16)
        let daily = Money.dailySavingsRate(mm)
        XCTAssertEqual(daily, 38.4 / 7, accuracy: 1e-9)
    }

    func testDailyDrinksAvoidedRateIncludesFreeDays() {
        // free: 4 days * 2 drinks = 8; paid: 3 * 0.8 * 2 = 4.8; weekly = 12.8
        let mm = MoneyModel(freeDaysPerWeek: 4, freeDrinksPerDay: 2, paidDaysPerWeek: 3, paidDrinksPerDay: 2, paidOutFrequencyPct: 80, avgSpendPerOuting: 16)
        let daily = Money.dailyDrinksAvoidedRate(mm)
        XCTAssertEqual(daily, 12.8 / 7, accuracy: 1e-9)
    }

    func testMoneySavedLifetimeIsNotReducedByARelapse() {
        let mm = MoneyModel(freeDaysPerWeek: 0, freeDrinksPerDay: 0, paidDaysPerWeek: 7, paidDrinksPerDay: 2, paidOutFrequencyPct: 100, avgSpendPerOuting: 5)
        // 15 lifetime days regardless of the relapse in between
        XCTAssertEqual(Money.moneySavedForDays(15, mm), 15 * 5, accuracy: 1e-9)
    }
}
