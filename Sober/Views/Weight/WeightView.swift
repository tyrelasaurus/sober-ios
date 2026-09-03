import SwiftUI
import Charts

struct WeightView: View {
    @EnvironmentObject var store: Store
    @State private var showLog = false
    @State private var editId: String?

    private var unit: WeightUnit { store.data.settings.weightUnit }
    private var ws: WeightStats { store.stats.weightStats }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgApp.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        statGrid
                        chart
                        history
                    }
                    .padding()
                }
            }
            .foregroundStyle(Theme.textPrimary)
            .navigationTitle("Weight")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Log a Weigh-In") { showLog = true }
                }
            }
            .sheet(isPresented: $showLog) {
                WeighInFormView(existing: nil).environmentObject(store)
            }
            .sheet(item: Binding(
                get: { editId.flatMap { id in store.data.weighIns.first { $0.id == id } } },
                set: { editId = $0?.id }
            )) { w in
                WeighInFormView(existing: w).environmentObject(store)
            }
        }
    }

    private var header: some View {
        Text("Track your physical transformation alongside your streak. We recommend weighing in about once a week, same time of day — day-to-day weight bounces around with water and food, and a weekly trend tells the real story.")
            .font(.caption)
            .foregroundStyle(Theme.textSecondary)
    }

    private var statGrid: some View {
        let current = Fmt.weightDisplay(ws.latestWeighIn?.weightKg, unit: unit)
        let change = ws.weightChangeKg.map { unit == .kg ? $0 : WeightLogic.kgToLb($0) }
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(icon: "⚖️", value: current.map { "\(Fmt.num1($0)) \(unit.rawValue)" } ?? "—", caption: "Current Weight")
            StatTile(icon: "📉", value: change.map { ($0 >= 0 ? "+" : "") + "\(Fmt.num1($0)) \(unit.rawValue)" } ?? "—", caption: ws.firstWeighIn.map { "Since \(Fmt.dateShort($0.date))" } ?? "Change")
            StatTile(icon: "💪", value: ws.latestWeighIn?.bodyFatPct.map { "\(Fmt.num1($0))%" } ?? "—", caption: "Body Fat %")
            StatTile(icon: "📏", value: ws.latestWeighIn?.bmi.map { Fmt.num1($0) } ?? "—", caption: "BMI")
        }
    }

    private var chart: some View {
        SectionCard(title: "Weight over time", subtitle: "\(ws.count) logged weigh-in\(ws.count == 1 ? "" : "s"), in \(unit == .lb ? "pounds" : "kilograms")") {
            let points = WeightLogic.sorted(store.data.weighIns).compactMap { w -> (String, Double)? in
                Fmt.weightDisplay(w.weightKg, unit: unit).map { (w.date, $0) }
            }
            if points.isEmpty {
                Text("No weigh-ins logged yet.").font(.caption).foregroundStyle(Theme.textTertiary)
            } else {
                Chart(points, id: \.0) { point in
                    LineMark(x: .value("Date", point.0), y: .value("Weight", point.1)).foregroundStyle(Theme.accent)
                }
                .chartXAxis(.hidden)
                .frame(height: 140)
            }
        }
    }

    private var history: some View {
        SectionCard(title: "Weigh-in history", subtitle: "\(ws.count) logged") {
            VStack(spacing: 0) {
                ForEach(WeightLogic.sorted(store.data.weighIns).reversed()) { w in
                    Button { editId = w.id } label: {
                        HStack {
                            Text(Fmt.relativeDay(w.date)).font(.caption.bold())
                            Spacer()
                            if let weight = Fmt.weightDisplay(w.weightKg, unit: unit) {
                                Text("\(Fmt.num1(weight)) \(unit.rawValue)").font(.caption2)
                            }
                            if let bf = w.bodyFatPct { Text("\(Fmt.num1(bf))% fat").font(.caption2).foregroundStyle(Theme.textSecondary) }
                        }
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.vertical, 6)
                    }
                    Divider().background(Theme.border)
                }
            }
        }
    }
}

struct WeighInFormView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let existing: WeighIn?

    @State private var date = Date()
    @State private var weight = ""
    @State private var bodyFat = ""
    @State private var muscleMass = ""
    @State private var bmi = ""
    @State private var note = ""

    private var unit: WeightUnit { store.data.settings.weightUnit }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgApp.ignoresSafeArea()
                Form {
                    Section {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                        HStack { Text("Weight (\(unit.rawValue))"); Spacer(); TextField("0", text: $weight).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                        HStack { Text("Body fat %"); Spacer(); TextField("optional", text: $bodyFat).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                        HStack { Text("Muscle mass (\(unit.rawValue))"); Spacer(); TextField("optional", text: $muscleMass).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                        HStack { Text("BMI"); Spacer(); TextField("optional", text: $bmi).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                        TextField("Note (optional)", text: $note)
                    }
                    .listRowBackground(Theme.card)

                    if existing != nil {
                        Button("Delete", role: .destructive) { deleteEntry() }
                            .listRowBackground(Theme.card)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .foregroundStyle(Theme.textPrimary)
            .navigationTitle(existing == nil ? "Log a Weigh-In" : "Edit Weigh-In")
            .navigationBarTitleDisplayMode(.inline)
            .dismissKeyboardToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear {
                guard let existing else { return }
                date = DateUtils.parseDate(existing.date)
                weight = Fmt.weightDisplay(existing.weightKg, unit: unit).map { String($0) } ?? ""
                bodyFat = existing.bodyFatPct.map { String($0) } ?? ""
                muscleMass = Fmt.weightDisplay(existing.muscleMassKg, unit: unit).map { String($0) } ?? ""
                bmi = existing.bmi.map { String($0) } ?? ""
                note = existing.note ?? ""
            }
        }
    }

    private func save() {
        var patch = WeighInPatch()
        patch.date = DateUtils.dateStr(from: date)
        patch.weightKg = .set(Fmt.weightToKg(Double(weight), unit: unit))
        patch.bodyFatPct = .set(Double(bodyFat))
        patch.muscleMassKg = .set(Fmt.weightToKg(Double(muscleMass), unit: unit))
        patch.bmi = .set(Double(bmi))
        patch.note = .set(note)
        store.upsertWeighIn(patch)
        dismiss()
    }

    private func deleteEntry() {
        if let existing { store.deleteWeighIn(id: existing.id) }
        dismiss()
    }
}
