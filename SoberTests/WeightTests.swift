import XCTest
@testable import Sober

final class WeightTests: XCTestCase {
    func testKgToLbAndBackRoundTripsAndMatchesKnownConversion() {
        XCTAssertEqual(WeightLogic.kgToLb(100), 220.46226218, accuracy: 1e-6)
        XCTAssertEqual(WeightLogic.lbToKg(WeightLogic.kgToLb(100)), 100, accuracy: 1e-9)
    }

    func testWeightStatsReturnsNilsAndIsDueWithNoWeighIns() {
        let stats = WeightLogic.stats([])
        XCTAssertEqual(stats.count, 0)
        XCTAssertNil(stats.firstWeighIn)
        XCTAssertNil(stats.weightChangeKg)
        XCTAssertTrue(stats.isDue)
    }

    func testWeightStatsComputesChangeFromFirstToLatestRegardlessOfInsertionOrder() {
        let weighIns = [
            WeighIn(id: "b", date: "2026-01-15", weightKg: 90, bodyFatPct: nil, muscleMassKg: nil, bmi: nil, note: nil, updatedAt: ""),
            WeighIn(id: "a", date: "2026-01-01", weightKg: 95, bodyFatPct: nil, muscleMassKg: nil, bmi: nil, note: nil, updatedAt: ""),
        ]
        let stats = WeightLogic.stats(weighIns, now: DateUtils.parseDate("2026-01-20"))
        XCTAssertEqual(stats.firstWeighIn?.date, "2026-01-01")
        XCTAssertEqual(stats.latestWeighIn?.date, "2026-01-15")
        XCTAssertEqual(stats.weightChangeKg ?? 0, -5, accuracy: 1e-9)
    }

    func testDueInDaysCountsDownOverTheWeeklyCadenceAndIsDueFlipsAtSevenDays() {
        let weighIns = [WeighIn(id: "a", date: "2026-01-01", weightKg: 90, bodyFatPct: nil, muscleMassKg: nil, bmi: nil, note: nil, updatedAt: "")]

        let stats3 = WeightLogic.stats(weighIns, now: DateUtils.parseDate("2026-01-04")) // 3 days later
        XCTAssertEqual(stats3.dueInDays, 4)
        XCTAssertFalse(stats3.isDue)

        let stats7 = WeightLogic.stats(weighIns, now: DateUtils.parseDate("2026-01-08")) // 7 days later
        XCTAssertEqual(stats7.dueInDays, 0)
        XCTAssertTrue(stats7.isDue)
    }
}
