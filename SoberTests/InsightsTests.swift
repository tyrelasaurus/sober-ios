import XCTest
@testable import Sober

final class InsightsTests: XCTestCase {
    func testTriggerTagCountsTalliesAndSortsByFrequency() {
        let records = [["stress", "social"], ["stress"], [], []]
        let counts = Insights.triggerTagCounts(records)
        XCTAssertEqual(counts[0].id, "stress")
        XCTAssertEqual(counts[0].count, 2)
        XCTAssertEqual(counts[1].id, "social")
        XCTAssertEqual(counts[1].count, 1)
        XCTAssertFalse(counts.contains { $0.count == 0 })
    }

    func testAvgCravingByTriggerRequiresMinSamplesBeforeIncludingATag() {
        let checkins = [
            CheckIn(id: "1", date: "2026-01-01", craving: 8, triggers: ["stress"]),
            CheckIn(id: "2", date: "2026-01-02", craving: 6, triggers: ["stress"]),
            CheckIn(id: "3", date: "2026-01-03", craving: 2, triggers: ["boredom"]), // only 1 sample
        ]
        let result = Insights.avgCravingByTrigger(checkins)
        let stress = result.first { $0.id == "stress" }
        XCTAssertNotNil(stress)
        XCTAssertEqual(stress?.avgCraving ?? 0, 7, accuracy: 1e-9)
        XCTAssertFalse(result.contains { $0.id == "boredom" })
    }

    func testSleepCorrelationComparesUnderVsOverSixHoursNilIfSparse() {
        let checkins = [
            CheckIn(id: "1", date: "2026-08-01", sleepHours: 4, craving: 7),
            CheckIn(id: "2", date: "2026-08-02", sleepHours: 5, craving: 5),
            CheckIn(id: "3", date: "2026-08-03", sleepHours: 8, craving: 1),
            CheckIn(id: "4", date: "2026-08-04", sleepHours: 9, craving: 2),
        ]
        let cmp = Insights.sleepCorrelation(checkins) { $0.craving }
        XCTAssertNotNil(cmp)
        XCTAssertEqual(cmp?.aAvg ?? 0, 6, accuracy: 1e-9)
        XCTAssertEqual(cmp?.bAvg ?? 0, 1.5, accuracy: 1e-9)

        let sparse = [
            CheckIn(id: "1", date: "2026-08-01", sleepHours: 4, craving: 7),
            CheckIn(id: "2", date: "2026-08-03", sleepHours: 8, craving: 1),
        ]
        XCTAssertNil(Insights.sleepCorrelation(sparse) { $0.craving })
    }

    func testExerciseDurationCorrelationSplitsAtMedianNotFixedCutoff() {
        // Someone who exercises almost every day — duration finds contrast
        // within those days even without enough non-exercise days.
        let checkins = [
            CheckIn(id: "1", date: "2026-01-01", mood: 3, exerciseMinutes: 15),
            CheckIn(id: "2", date: "2026-01-02", mood: 3, exerciseMinutes: 20),
            CheckIn(id: "3", date: "2026-01-03", mood: 5, exerciseMinutes: 45),
            CheckIn(id: "4", date: "2026-01-04", mood: 4, exerciseMinutes: 60),
        ]
        let cmp = Insights.exerciseDurationCorrelation(checkins) { $0.mood.map(Double.init) }
        XCTAssertNotNil(cmp)
        XCTAssertEqual(cmp?.aAvg ?? 0, 3, accuracy: 1e-9)
        XCTAssertEqual(cmp?.bAvg ?? 0, 4.5, accuracy: 1e-9)

        // A fixed 30-min cutoff would fail here — every session is 30+ min —
        // but the median still finds a balanced split.
        let allLong = [
            CheckIn(id: "1", date: "2026-01-01", exerciseMinutes: 30, craving: 6),
            CheckIn(id: "2", date: "2026-01-02", exerciseMinutes: 30, craving: 5),
            CheckIn(id: "3", date: "2026-01-03", exerciseMinutes: 90, craving: 2),
            CheckIn(id: "4", date: "2026-01-04", exerciseMinutes: 90, craving: 1),
        ]
        let cmp2 = Insights.exerciseDurationCorrelation(allLong) { $0.craving }
        XCTAssertNotNil(cmp2)
        XCTAssertEqual(cmp2?.aAvg ?? 0, 5.5, accuracy: 1e-9)
        XCTAssertEqual(cmp2?.bAvg ?? 0, 1.5, accuracy: 1e-9)

        // No variance at all genuinely has nothing to compare.
        let noVariance = [
            CheckIn(id: "1", date: "2026-01-01", mood: 3, exerciseMinutes: 30),
            CheckIn(id: "2", date: "2026-01-02", mood: 4, exerciseMinutes: 30),
            CheckIn(id: "3", date: "2026-01-03", mood: 5, exerciseMinutes: 30),
        ]
        XCTAssertNil(Insights.exerciseDurationCorrelation(noVariance) { $0.mood.map(Double.init) })
    }

    func testExerciseIntensityCorrelationComparesLightVsModerateVigorous() {
        let checkins = [
            CheckIn(id: "1", date: "2026-01-01", exerciseIntensity: "light", craving: 2),
            CheckIn(id: "2", date: "2026-01-02", exerciseIntensity: "light", craving: 3),
            CheckIn(id: "3", date: "2026-01-03", exerciseIntensity: "moderate", craving: 1),
            CheckIn(id: "4", date: "2026-01-04", exerciseIntensity: "vigorous", craving: 0),
        ]
        let cmp = Insights.exerciseIntensityCorrelation(checkins) { $0.craving }
        XCTAssertNotNil(cmp)
        XCTAssertEqual(cmp?.aAvg ?? 0, 2.5, accuracy: 1e-9)
        XCTAssertEqual(cmp?.bAvg ?? 0, 0.5, accuracy: 1e-9)
    }
}
