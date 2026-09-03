import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: Store
    @State private var step = 0
    @State private var startDate = Date()
    @State private var freeDaysPerWeek: Double = 0
    @State private var freeDrinksPerDay: Double = 0
    @State private var paidDaysPerWeek: Double = 7
    @State private var paidDrinksPerDay: Double = 2
    @State private var paidOutFrequencyPct: Double = 100
    @State private var avgSpendPerOuting: Double = 16
    @State private var currencySymbol = "$"

    private var dailyRate: Double {
        (paidDaysPerWeek * (paidOutFrequencyPct / 100) * avgSpendPerOuting) / 7
    }
    private var weeklyDrinks: Double {
        freeDaysPerWeek * freeDrinksPerDay + paidDaysPerWeek * (paidOutFrequencyPct / 100) * paidDrinksPerDay
    }

    var body: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()
            VStack(spacing: 20) {
                HStack(spacing: 6) {
                    ForEach(0..<4) { i in
                        Circle().fill(i == step ? Theme.accent : Theme.border).frame(width: 6, height: 6)
                    }
                }
                Spacer()
                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: startDateStep
                    case 2: baselineStep
                    default: confirmStep
                    }
                }
                Spacer()
            }
            .padding(24)
        }
        .foregroundStyle(Theme.textPrimary)
    }

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Text("🌱").font(.system(size: 56))
            Text("Welcome to Sober").font(.title2.bold())
            Text("A private, on-this-phone tracker for your sobriety — streaks, money saved, sleep, mood, and journaling. Nothing leaves your phone.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
            Button("Get Started") { step = 1 }
                .buttonStyle(.borderedProminent)
        }
    }

    private var startDateStep: some View {
        VStack(spacing: 16) {
            Text("When did your current streak start?").font(.title3.bold())
            Text("This sets Day 1. If today is day one, just leave it as-is.")
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            DatePicker("Start date", selection: $startDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(Theme.accent)
            navButtons(next: { step = 2 })
        }
    }

    private var baselineStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("What were you really spending?").font(.title3.bold())
                Text("Split it into days you drank for free (work perks, open bar) and days you actually paid. Rough numbers are fine — refine later in Settings.")
                    .foregroundStyle(Theme.textSecondary)

                Text("Free-access days").font(.subheadline.bold())
                HStack(spacing: 12) {
                    WheelCountPicker(title: "Days/week", range: 0...7, selection: $freeDaysPerWeek)
                    WheelCountPicker(title: "Drinks/day", range: 0...5, plusAtMax: true, selection: $freeDrinksPerDay)
                }
                .frame(height: 110)

                Text("Days you'd pay").font(.subheadline.bold())
                HStack(spacing: 12) {
                    WheelCountPicker(title: "Days/week", range: 0...7, selection: $paidDaysPerWeek)
                    WheelCountPicker(title: "Drinks/day", range: 0...5, plusAtMax: true, selection: $paidDrinksPerDay)
                }
                .frame(height: 110)
                Stepper("% of those days you actually went: \(Int(paidOutFrequencyPct))%", value: $paidOutFrequencyPct, in: 0...100, step: 5)
                Stepper("Avg spend on a night out: \(currencySymbol)\(Int(avgSpendPerOuting))", value: $avgSpendPerOuting, in: 0...500, step: 5)

                Text("Currency symbol").font(.subheadline.bold())
                TextField("$", text: $currencySymbol)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .dismissKeyboardToolbar()

                navButtons(next: { step = 3 })
            }
        }
    }

    private var confirmStep: some View {
        VStack(spacing: 16) {
            Text("✅").font(.system(size: 56))
            Text("You're all set").font(.title2.bold())
            Text("Day 1 is \(Fmt.dateLong(DateUtils.dateStr(from: startDate))). At roughly \(currencySymbol)\(String(format: "%.2f", dailyRate))/day, every week sober is about \(currencySymbol)\(String(format: "%.0f", dailyRate * 7)) saved and \(Fmt.num1(weeklyDrinks)) drinks avoided. That total keeps growing even through a rough day — it never resets.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
            Button("Start Tracking") {
                let mm = MoneyModel(
                    freeDaysPerWeek: freeDaysPerWeek, freeDrinksPerDay: freeDrinksPerDay,
                    paidDaysPerWeek: paidDaysPerWeek, paidDrinksPerDay: paidDrinksPerDay,
                    paidOutFrequencyPct: paidOutFrequencyPct, avgSpendPerOuting: avgSpendPerOuting
                )
                store.completeOnboarding(
                    startDate: DateUtils.dateStr(from: startDate), moneyModel: mm,
                    currencySymbol: currencySymbol.isEmpty ? "$" : currencySymbol
                )
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func navButtons(next: @escaping () -> Void) -> some View {
        HStack {
            Button("Back") { step = max(0, step - 1) }.buttonStyle(.bordered)
            Spacer()
            Button("Continue", action: next).buttonStyle(.borderedProminent)
        }
    }
}
