import XCTest
@testable import Sober

final class MilestonesTests: XCTestCase {
    func testMilestoneStatusMarksAchievedMilestonesCorrectlyAtDay30() {
        let status = Milestones.status(for: 30)
        let oneMonth = status.first { $0.id == "m1" }
        let threeMonths = status.first { $0.id == "m3" }
        XCTAssertEqual(oneMonth?.achieved, true)
        XCTAssertEqual(threeMonths?.achieved, false)
    }

    func testNextMilestoneReturnsFirstUnmetMilestone() {
        XCTAssertEqual(Milestones.next(for: 30)?.id, "m3")
    }

    func testBestMilestonesIsScopedToLongestStreakAndSurvivesARelapse() {
        // Longest streak of 150 days should show 3-month (90) as achieved,
        // even if the current streak (post-relapse) is much shorter.
        let bestStatus = Milestones.status(for: 150)
        XCTAssertEqual(bestStatus.first { $0.id == "m3" }?.achieved, true)
        XCTAssertEqual(bestStatus.first { $0.id == "m6" }?.achieved, false)

        let currentStatus = Milestones.status(for: 10)
        XCTAssertEqual(currentStatus.first { $0.id == "m3" }?.achieved, false)
    }

    func testMilestoneTrackPositionPlacesEachMilestoneAtAnEvenlySpacedTick() {
        let segmentWidth = 100.0 / Double(Milestones.all.count)
        XCTAssertEqual(Milestones.trackPosition(0), 0, accuracy: 1e-9)
        // Day 1 *is* the "24 Hours" milestone itself, so it should land
        // exactly at the end of the first evenly-spaced segment.
        XCTAssertEqual(Milestones.trackPosition(1), segmentWidth, accuracy: 1e-9)
        // A day part-way toward the second milestone (3 days) should be
        // interpolated strictly between the first and second ticks.
        let partial = Milestones.trackPosition(2)
        XCTAssertGreaterThan(partial, segmentWidth)
        XCTAssertLessThan(partial, segmentWidth * 2)
    }
}
