import Foundation

/// A single sobriety streak span. `endDate == nil` means it's the currently
/// active streak. Mirrors store.js's period shape exactly.
struct Period: Codable, Identifiable, Equatable {
    var id: String
    var startDate: String
    var endDate: String?
    var endReason: String?
    var triggers: [String]?
    var note: String?
}

/// One day's check-in record. Fields are optional/nil when not yet logged —
/// matches store.js's upsertCheckin, which merges partial updates field by
/// field rather than overwriting the whole record.
struct CheckIn: Codable, Identifiable, Equatable {
    var id: String
    var date: String
    var mood: Int?
    var sleepHours: Double?
    var sleepQuality: String?
    var ateWell: Bool?
    var exercised: Bool?
    var exerciseMinutes: Double?
    var exerciseIntensity: String?
    var craving: Double?
    var note: String?
    var triggers: [String]
    var updatedAt: String

    init(
        id: String, date: String, mood: Int? = nil, sleepHours: Double? = nil,
        sleepQuality: String? = nil, ateWell: Bool? = nil, exercised: Bool? = nil,
        exerciseMinutes: Double? = nil, exerciseIntensity: String? = nil,
        craving: Double? = nil, note: String? = nil, triggers: [String] = [],
        updatedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.date = date
        self.mood = mood
        self.sleepHours = sleepHours
        self.sleepQuality = sleepQuality
        self.ateWell = ateWell
        self.exercised = exercised
        self.exerciseMinutes = exerciseMinutes
        self.exerciseIntensity = exerciseIntensity
        self.craving = craving
        self.note = note
        self.triggers = triggers
        self.updatedAt = updatedAt
    }
}

/// One weigh-in. Weight/muscle mass are always stored in kilograms regardless
/// of the user's display unit — same convention as calc.js's kgToLb/lbToKg.
struct WeighIn: Codable, Identifiable, Equatable {
    var id: String
    var date: String
    var weightKg: Double?
    var bodyFatPct: Double?
    var muscleMassKg: Double?
    var bmi: Double?
    var note: String?
    var updatedAt: String
}

struct JournalEntry: Codable, Identifiable, Equatable {
    var id: String
    var date: String
    var createdAt: String
    var title: String
    var body: String
    var mood: Int?
}

struct MoneyModel: Codable, Equatable {
    var freeDaysPerWeek: Double
    var freeDrinksPerDay: Double
    var paidDaysPerWeek: Double
    var paidDrinksPerDay: Double
    var paidOutFrequencyPct: Double
    var avgSpendPerOuting: Double

    static let `default` = MoneyModel(
        freeDaysPerWeek: 0, freeDrinksPerDay: 0,
        paidDaysPerWeek: 7, paidDrinksPerDay: 2,
        paidOutFrequencyPct: 100, avgSpendPerOuting: 16
    )
}

enum WeightUnit: String, Codable {
    case lb, kg
}

struct AppSettings: Codable, Equatable {
    var currency: String = "USD"
    var currencySymbol: String = "$"
    var weightUnit: WeightUnit = .lb
    var moneyModel: MoneyModel = .default
}

/// Top-level container matching store.js's defaultData() shape exactly, so a
/// JSON export from the Mac app can be dropped in and read here unmodified.
struct AppData: Codable, Equatable {
    var version: Int = 1
    var onboarded: Bool = false
    var settings: AppSettings = AppSettings()
    var periods: [Period] = []
    var checkins: [CheckIn] = []
    var journal: [JournalEntry] = []
    var weighIns: [WeighIn] = []
}

func makeId() -> String {
    let millis = Int64(Date().timeIntervalSince1970 * 1000)
    let rand = String(UUID().uuidString.prefix(8)).lowercased()
    return String(millis, radix: 36) + rand
}
