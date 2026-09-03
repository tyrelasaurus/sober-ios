import XCTest
@testable import Sober

final class StreaksTests: XCTestCase {
    func testDaysBetweenCountsWholeDays() {
        XCTAssertEqual(DateUtils.daysBetween("2026-01-01", "2026-01-05"), 4)
    }

    func testCurrentStreakDaysReflectsAnOpenPeriod() {
        let periods = [Period(id: "a", startDate: "2026-01-01", endDate: nil, endReason: nil)]
        let now = DateUtils.parseDate("2026-01-11")
        XCTAssertEqual(Streaks.currentStreakDays(periods, now: now), 10)
    }

    func testRecordRelapseClosesCurrentPeriodAndOpensNewOneAtZeroDays() {
        let periods = [Period(id: "a", startDate: "2026-01-01", endDate: nil, endReason: nil)]
        let updated = Streaks.recordRelapse(periods, dateStr: "2026-01-11")
        XCTAssertEqual(updated.count, 2)
        XCTAssertEqual(updated[0].endDate, "2026-01-11")
        XCTAssertEqual(updated[0].endReason, "relapse")
        XCTAssertNil(updated[1].endDate)
        XCTAssertEqual(updated[1].startDate, "2026-01-11")
    }

    func testLongestStreakDaysPicksMaxAcrossClosedAndOpenPeriods() {
        let periods = [
            Period(id: "a", startDate: "2026-01-01", endDate: "2026-01-11", endReason: "relapse"),
            Period(id: "b", startDate: "2026-02-01", endDate: nil, endReason: nil),
        ]
        let now = DateUtils.parseDate("2026-02-06")
        XCTAssertEqual(Streaks.longestStreakDays(periods, now: now), 10)
    }

    func testTotalSoberDaysSumsAcrossPeriodsIncludingTheOpenOne() {
        let periods = [
            Period(id: "a", startDate: "2026-01-01", endDate: "2026-01-11", endReason: "relapse"),
            Period(id: "b", startDate: "2026-02-01", endDate: nil, endReason: nil),
        ]
        let now = DateUtils.parseDate("2026-02-06")
        XCTAssertEqual(Streaks.totalSoberDays(periods, now: now), 15)
    }

    func testRecordRelapseAttachesTriggersToThePeriodThatJustClosed() {
        let periods = [Period(id: "a", startDate: "2026-01-01", endDate: nil, endReason: nil)]
        let updated = Streaks.recordRelapse(periods, dateStr: "2026-01-11", triggers: ["stress"], note: "rough day")
        XCTAssertEqual(updated[0].triggers, ["stress"])
        XCTAssertEqual(updated[0].note, "rough day")
        XCTAssertNil(updated[1].triggers)
    }
}
