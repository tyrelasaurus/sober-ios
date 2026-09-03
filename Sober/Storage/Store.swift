import Foundation
import Combine

/// Represents a single field in a partial update. `.unset` means the field
/// wasn't included in this patch at all — keep whatever value is already
/// stored. `.set(nil)` means the field was included and explicitly cleared.
/// `.set(value)` writes that value. This mirrors store.js's `'key' in entry`
/// check, which distinguishes "omitted" from "explicitly null" — a quick
/// mood-only tap must never wipe a morning's sleep data just because it
/// didn't mention sleep, but a Full Check-In blanking a field must still
/// clear it. Getting this wrong was a real data-loss bug in the Mac app once.
enum FieldUpdate<T> {
    case unset
    case set(T?)

    func resolve(existing: T?) -> T? {
        switch self {
        case .unset: return existing
        case .set(let v): return v
        }
    }
}

/// Local JSON-file persistence + in-memory state, mirroring src/main/store.js.
/// Data lives in the app's Documents directory as a single sober-data.json
/// file — nothing is uploaded anywhere, matching the Mac app's philosophy.
final class Store: ObservableObject {
    @Published private(set) var data: AppData
    @Published private(set) var stats: Stats

    private let fileURL: URL

    init(directory: URL? = nil) {
        let dir = directory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = dir.appendingPathComponent("sober-data.json")
        let loaded = Store.load(from: fileURL)
        self.data = loaded
        self.stats = StatsEngine.compute(loaded)
    }

    private static func load(from url: URL) -> AppData {
        guard let raw = try? Data(contentsOf: url) else { return AppData() }
        do {
            return try JSONDecoder().decode(AppData.self, from: raw)
        } catch {
            // Corrupt or unreadable file: back it up and start fresh rather
            // than crashing, matching store.js's fallback behavior.
            let backup = url.appendingPathExtension("corrupt-\(Int(Date().timeIntervalSince1970)).bak")
            try? FileManager.default.copyItem(at: url, to: backup)
            return AppData()
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let encoded = try? encoder.encode(data) else { return }
        let tmp = fileURL.appendingPathExtension("tmp")
        do {
            try encoded.write(to: tmp, options: .atomic)
            _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: tmp)
        } catch {
            try? encoded.write(to: fileURL, options: .atomic)
        }
    }

    private func recompute() {
        stats = StatsEngine.compute(data)
    }

    // MARK: - Onboarding / settings

    func completeOnboarding(startDate: String, moneyModel: MoneyModel, currencySymbol: String) {
        data.settings.moneyModel = moneyModel
        data.settings.currencySymbol = currencySymbol
        data.periods = Streaks.startPeriod(data.periods, startDateStr: startDate)
        data.onboarded = true
        save()
        recompute()
    }

    func updateSettings(_ settings: AppSettings) {
        data.settings = settings
        save()
        recompute()
    }

    // MARK: - Streak management

    func recordRelapse(date: String = DateUtils.todayStr(), triggers: [String] = [], note: String = "") {
        data.periods = Streaks.recordRelapse(data.periods, dateStr: date, triggers: triggers, note: note)
        save()
        recompute()
    }

    func setStreakStartDate(_ dateStr: String) {
        if let idx = data.periods.firstIndex(where: { $0.endDate == nil }) {
            data.periods[idx].startDate = dateStr
        } else {
            data.periods = Streaks.startPeriod(data.periods, startDateStr: dateStr)
        }
        save()
        recompute()
    }

    // MARK: - Check-ins

    /// Merges a check-in into the day's single record, field by field — see
    /// `FieldUpdate` above for exactly what "merge" means here.
    @discardableResult
    func upsertCheckin(_ patch: CheckInPatch) -> CheckIn {
        let date = patch.date ?? DateUtils.todayStr()
        let idx = data.checkins.firstIndex { $0.date == date }
        let existing = idx.map { data.checkins[$0] }

        var clean = CheckIn(id: existing?.id ?? makeId(), date: date)
        clean.mood = patch.mood.resolve(existing: existing?.mood)
        clean.sleepHours = patch.sleepHours.resolve(existing: existing?.sleepHours)
        clean.sleepQuality = patch.sleepQuality.resolve(existing: existing?.sleepQuality)
        clean.ateWell = patch.ateWell.resolve(existing: existing?.ateWell)
        clean.exercised = patch.exercised.resolve(existing: existing?.exercised)
        clean.exerciseMinutes = patch.exerciseMinutes.resolve(existing: existing?.exerciseMinutes)
        clean.exerciseIntensity = patch.exerciseIntensity.resolve(existing: existing?.exerciseIntensity)
        clean.craving = patch.craving.resolve(existing: existing?.craving)
        clean.note = patch.note.resolve(existing: existing?.note) ?? ""
        clean.triggers = patch.triggers.resolve(existing: existing?.triggers) ?? []
        clean.updatedAt = ISO8601DateFormatter().string(from: Date())

        if let idx { data.checkins[idx] = clean } else { data.checkins.append(clean) }
        data.checkins.sort { $0.date < $1.date }
        save()
        recompute()
        return clean
    }

    func deleteCheckin(id: String) {
        data.checkins.removeAll { $0.id == id }
        save()
        recompute()
    }

    // MARK: - Weigh-ins

    @discardableResult
    func upsertWeighIn(_ patch: WeighInPatch) -> WeighIn {
        let date = patch.date ?? DateUtils.todayStr()
        let idx = data.weighIns.firstIndex { $0.date == date }
        let existing = idx.map { data.weighIns[$0] }

        let clean = WeighIn(
            id: existing?.id ?? makeId(), date: date,
            weightKg: patch.weightKg.resolve(existing: existing?.weightKg),
            bodyFatPct: patch.bodyFatPct.resolve(existing: existing?.bodyFatPct),
            muscleMassKg: patch.muscleMassKg.resolve(existing: existing?.muscleMassKg),
            bmi: patch.bmi.resolve(existing: existing?.bmi),
            note: patch.note.resolve(existing: existing?.note) ?? "",
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        if let idx { data.weighIns[idx] = clean } else { data.weighIns.append(clean) }
        data.weighIns.sort { $0.date < $1.date }
        save()
        recompute()
        return clean
    }

    func deleteWeighIn(id: String) {
        data.weighIns.removeAll { $0.id == id }
        save()
        recompute()
    }

    // MARK: - Journal

    @discardableResult
    func addJournalEntry(title: String, body: String, mood: Int?, date: String? = nil) -> JournalEntry {
        let entry = JournalEntry(
            id: makeId(), date: date ?? DateUtils.todayStr(),
            createdAt: ISO8601DateFormatter().string(from: Date()),
            title: title, body: body, mood: mood
        )
        data.journal.insert(entry, at: 0)
        save()
        recompute()
        return entry
    }

    func updateJournalEntry(id: String, title: String, body: String, mood: Int?) {
        guard let idx = data.journal.firstIndex(where: { $0.id == id }) else { return }
        data.journal[idx].title = title
        data.journal[idx].body = body
        data.journal[idx].mood = mood
        save()
        recompute()
    }

    func deleteJournalEntry(id: String) {
        data.journal.removeAll { $0.id == id }
        save()
        recompute()
    }

    // MARK: - Danger zone

    func resetAllData() {
        data = AppData()
        save()
        recompute()
    }

    /// Replaces the whole store with imported data (e.g. a JSON export from
    /// the Mac app), for manual cross-device transfer until real sync exists.
    func importData(_ imported: AppData) {
        data = imported
        save()
        recompute()
    }

    func exportURL() -> URL { fileURL }
}

struct CheckInPatch {
    var date: String?
    var mood: FieldUpdate<Int> = .unset
    var sleepHours: FieldUpdate<Double> = .unset
    var sleepQuality: FieldUpdate<String> = .unset
    var ateWell: FieldUpdate<Bool> = .unset
    var exercised: FieldUpdate<Bool> = .unset
    var exerciseMinutes: FieldUpdate<Double> = .unset
    var exerciseIntensity: FieldUpdate<String> = .unset
    var craving: FieldUpdate<Double> = .unset
    var note: FieldUpdate<String> = .unset
    var triggers: FieldUpdate<[String]> = .unset
}

struct WeighInPatch {
    var date: String?
    var weightKg: FieldUpdate<Double> = .unset
    var bodyFatPct: FieldUpdate<Double> = .unset
    var muscleMassKg: FieldUpdate<Double> = .unset
    var bmi: FieldUpdate<Double> = .unset
    var note: FieldUpdate<String> = .unset
}
