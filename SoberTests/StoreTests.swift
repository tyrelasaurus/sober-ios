import XCTest
@testable import Sober

final class StoreTests: XCTestCase {
    private func tempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func testStorePersistsToDiskAndReloadsIdentically() {
        let dir = tempDir()
        let store1 = Store(directory: dir)
        store1.completeOnboarding(startDate: "2026-01-01", moneyModel: .default, currencySymbol: "$")
        var patch = CheckInPatch()
        patch.date = "2026-01-05"
        patch.mood = .set(4)
        store1.upsertCheckin(patch)

        let store2 = Store(directory: dir)
        XCTAssertEqual(store2.data.onboarded, true)
        XCTAssertEqual(store2.data.checkins.first?.mood, 4)
    }

    func testUpsertCheckinReplacesSameDayEntryInsteadOfDuplicating() {
        let store = Store(directory: tempDir())
        var patch = CheckInPatch()
        patch.date = "2026-01-05"
        patch.mood = .set(3)
        store.upsertCheckin(patch)
        patch.mood = .set(5)
        store.upsertCheckin(patch)
        XCTAssertEqual(store.data.checkins.count, 1)
        XCTAssertEqual(store.data.checkins.first?.mood, 5)
    }

    /// A quick mood-only tap must not wipe fields it doesn't mention — the
    /// exact bug fixed in the Mac app's v1.1.1 (see CHANGELOG in sober-app).
    func testUpsertCheckinPreservesFieldsOmittedFromALaterPartialUpdate() {
        let store = Store(directory: tempDir())
        var morning = CheckInPatch()
        morning.date = "2026-01-05"
        morning.sleepHours = .set(7.5)
        store.upsertCheckin(morning)

        var moodTap = CheckInPatch()
        moodTap.date = "2026-01-05"
        moodTap.mood = .set(4)
        // sleepHours deliberately left .unset, simulating a quick tap that
        // only knows about mood.
        store.upsertCheckin(moodTap)

        let saved = store.data.checkins.first { $0.date == "2026-01-05" }
        XCTAssertEqual(saved?.mood, 4)
        XCTAssertEqual(saved?.sleepHours, 7.5) // must survive the mood-only update
    }

    /// Explicitly setting a field to nil (Full Check-In blanking it) must
    /// still clear it — only *omitted* fields are protected.
    func testUpsertCheckinClearsAFieldWhenExplicitlyIncludedAsNil() {
        let store = Store(directory: tempDir())
        var patch = CheckInPatch()
        patch.date = "2026-01-05"
        patch.sleepHours = .set(7.5)
        store.upsertCheckin(patch)

        patch.sleepHours = .set(nil) // explicit clear
        store.upsertCheckin(patch)

        XCTAssertNil(store.data.checkins.first { $0.date == "2026-01-05" }?.sleepHours)
    }

    func testStoreHandlesCorruptJSONFileByFallingBackToDefaults() {
        let dir = tempDir()
        let fileURL = dir.appendingPathComponent("sober-data.json")
        try? "not valid json {".write(to: fileURL, atomically: true, encoding: .utf8)
        let store = Store(directory: dir)
        XCTAssertEqual(store.data.onboarded, false)
        XCTAssertEqual(store.data.checkins.count, 0)
    }

    func testUpsertWeighInReplacesSameDayEntryInsteadOfDuplicating() {
        let store = Store(directory: tempDir())
        var patch = WeighInPatch()
        patch.date = "2026-01-05"
        patch.weightKg = .set(90)
        store.upsertWeighIn(patch)
        patch.weightKg = .set(88)
        store.upsertWeighIn(patch)
        XCTAssertEqual(store.data.weighIns.count, 1)
        XCTAssertEqual(store.data.weighIns.first?.weightKg, 88)
    }

    func testDeleteWeighInRemovesOnlyTheTargetedEntry() {
        let store = Store(directory: tempDir())
        var a = WeighInPatch(); a.date = "2026-01-01"; a.weightKg = .set(90)
        var b = WeighInPatch(); b.date = "2026-01-08"; b.weightKg = .set(89)
        let saved = store.upsertWeighIn(a)
        store.upsertWeighIn(b)
        store.deleteWeighIn(id: saved.id)
        XCTAssertEqual(store.data.weighIns.count, 1)
        XCTAssertEqual(store.data.weighIns.first?.date, "2026-01-08")
    }

    func testRecordRelapseResetsStreakButKeepsHistory() {
        let store = Store(directory: tempDir())
        store.completeOnboarding(startDate: "2026-01-01", moneyModel: .default, currencySymbol: "$")
        store.recordRelapse(date: "2026-01-11")
        XCTAssertEqual(store.data.periods.count, 2)
        XCTAssertEqual(Streaks.numRelapses(store.data.periods), 1)
        let lifetimeDays = Streaks.totalSoberDays(store.data.periods, now: DateUtils.parseDate("2026-01-11"))
        XCTAssertEqual(lifetimeDays, 10)
    }
}
