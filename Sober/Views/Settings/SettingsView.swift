import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @State private var currencyCode = "USD"
    @State private var currencySymbol = "$"
    @State private var startDate = Date()
    @State private var freeDaysPerWeek: Double = 0
    @State private var freeDrinksPerDay: Double = 0
    @State private var paidDaysPerWeek: Double = 7
    @State private var paidDrinksPerDay: Double = 2
    @State private var paidOutFrequencyPct: Double = 100
    @State private var avgSpendPerOuting: Double = 16
    @State private var weightUnit: WeightUnit = .lb
    @State private var showResetConfirm = false

    private var estimate: (daily: Double, weekly: Double) {
        let mm = MoneyModel(
            freeDaysPerWeek: freeDaysPerWeek, freeDrinksPerDay: freeDrinksPerDay,
            paidDaysPerWeek: paidDaysPerWeek, paidDrinksPerDay: paidDrinksPerDay,
            paidOutFrequencyPct: paidOutFrequencyPct, avgSpendPerOuting: avgSpendPerOuting
        )
        let daily = Money.dailySavingsRate(mm)
        return (daily, daily * 7)
    }
    private var weeklyDrinks: Double {
        freeDaysPerWeek * freeDrinksPerDay + paidDaysPerWeek * (paidOutFrequencyPct / 100) * paidDrinksPerDay
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgApp.ignoresSafeArea()
                Form {
                    Section("Money saved calculation") {
                        CurrencyPicker(currencyCode: $currencyCode, currencySymbol: $currencySymbol)
                        DatePicker("Current streak start date", selection: $startDate, in: ...Date(), displayedComponents: .date)
                        Text("Free-access days").font(.caption).foregroundStyle(Theme.textSecondary)
                        HStack(spacing: 12) {
                            WheelCountPicker(title: "Days/week", range: 0...7, selection: $freeDaysPerWeek)
                            WheelCountPicker(title: "Drinks/day", range: 0...5, plusAtMax: true, selection: $freeDrinksPerDay)
                        }
                        .frame(height: 110)

                        Text("Days you'd pay").font(.caption).foregroundStyle(Theme.textSecondary)
                        HStack(spacing: 12) {
                            WheelCountPicker(title: "Days/week", range: 0...7, selection: $paidDaysPerWeek)
                            WheelCountPicker(title: "Drinks/day", range: 0...5, plusAtMax: true, selection: $paidDrinksPerDay)
                        }
                        .frame(height: 110)
                        Stepper("Go-out frequency: \(Int(paidOutFrequencyPct))%", value: $paidOutFrequencyPct, in: 0...100, step: 5)
                        Stepper("Avg spend/outing: \(Int(avgSpendPerOuting))", value: $avgSpendPerOuting, in: 0...500, step: 5)
                        Text("Estimated: \(currencySymbol)\(String(format: "%.2f", estimate.daily))/day (\(currencySymbol)\(String(format: "%.0f", estimate.weekly))/week) · \(Fmt.num1(weeklyDrinks)) drinks avoided/week")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        Button("Save Changes") { saveSettings() }
                    }
                    .listRowBackground(Theme.card)

                    Section("Units") {
                        Picker("Weight unit", selection: $weightUnit) {
                            Text("Pounds (lb)").tag(WeightUnit.lb)
                            Text("Kilograms (kg)").tag(WeightUnit.kg)
                        }
                        .onChange(of: weightUnit) { saveSettings() }
                    }
                    .listRowBackground(Theme.card)

                    Section("Your data") {
                        Text("Everything is stored locally on this phone — nothing is uploaded anywhere.")
                            .font(.caption).foregroundStyle(Theme.textSecondary)
                        ShareLink("Export as JSON", item: store.exportURL())
                    }
                    .listRowBackground(Theme.card)

                    Section("Danger zone") {
                        Text("Permanently deletes your streak history, check-ins, and journal entries.")
                            .font(.caption).foregroundStyle(Theme.textSecondary)
                        Button("Reset All Data", role: .destructive) { showResetConfirm = true }
                    }
                    .listRowBackground(Theme.card)

                    Text("Sober is a personal tracking tool, not a medical device. It doesn't replace professional treatment or support — if you need help, a doctor, therapist, or addiction specialist is always the best place to start.")
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                        .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .foregroundStyle(Theme.textPrimary)
            .navigationTitle("Settings")
            .onAppear(perform: load)
            .confirmationDialog("Reset All Data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Delete Everything", role: .destructive) { store.resetAllData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your streak history, check-ins, and journal entries. This cannot be undone.")
            }
        }
    }

    private func load() {
        let s = store.data.settings
        currencyCode = s.currency
        currencySymbol = s.currencySymbol
        weightUnit = s.weightUnit
        let mm = s.moneyModel
        freeDaysPerWeek = mm.freeDaysPerWeek
        freeDrinksPerDay = mm.freeDrinksPerDay
        paidDaysPerWeek = mm.paidDaysPerWeek
        paidDrinksPerDay = mm.paidDrinksPerDay
        paidOutFrequencyPct = mm.paidOutFrequencyPct
        avgSpendPerOuting = mm.avgSpendPerOuting
        if let current = store.data.periods.first(where: { $0.endDate == nil }) {
            startDate = DateUtils.parseDate(current.startDate)
        }
    }

    private func saveSettings() {
        var s = store.data.settings
        s.currency = currencyCode
        s.currencySymbol = currencySymbol
        s.weightUnit = weightUnit
        s.moneyModel = MoneyModel(
            freeDaysPerWeek: freeDaysPerWeek, freeDrinksPerDay: freeDrinksPerDay,
            paidDaysPerWeek: paidDaysPerWeek, paidDrinksPerDay: paidDrinksPerDay,
            paidOutFrequencyPct: paidOutFrequencyPct, avgSpendPerOuting: avgSpendPerOuting
        )
        store.updateSettings(s)
        store.setStreakStartDate(DateUtils.dateStr(from: startDate))
    }
}
