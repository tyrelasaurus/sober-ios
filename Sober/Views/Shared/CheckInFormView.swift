import SwiftUI

/// Full check-in editor for a given date — mirrors dashboard.js's
/// openCheckinModal. Used both for "today" (Overview) and for
/// editing/backfilling a past day (Calendar).
struct CheckInFormView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let date: String

    @State private var mood: Int?
    @State private var sleepHours: String
    @State private var craving: Double
    @State private var ateWell: Bool
    @State private var exercised: Bool
    @State private var exerciseMinutes: String
    @State private var exerciseIntensity: String
    @State private var note: String
    @State private var triggers: [String]
    @State private var showDeleteConfirm = false
    @State private var existingId: String?

    init(date: String) {
        self.date = date
        // NOTE: default state; real values are loaded in onAppear from the
        // store, since @State can't read environment objects at init time.
        _mood = State(initialValue: nil)
        _sleepHours = State(initialValue: "")
        _craving = State(initialValue: 0)
        _ateWell = State(initialValue: false)
        _exercised = State(initialValue: false)
        _exerciseMinutes = State(initialValue: "")
        _exerciseIntensity = State(initialValue: "")
        _note = State(initialValue: "")
        _triggers = State(initialValue: [])
        _existingId = State(initialValue: nil)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgApp.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(Fmt.dateLong(date)).font(.subheadline).foregroundStyle(Theme.textSecondary)

                        labeled("Mood") { MoodPicker(mood: $mood) }

                        labeled("Sleep (hours)") {
                            TextField("7.5", text: $sleepHours).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                        }

                        labeled("Craving (0-10)") {
                            VStack(alignment: .leading) {
                                Slider(value: $craving, in: 0...10, step: 1).tint(Theme.accent)
                                Text("\(Int(craving))").font(.caption).foregroundStyle(Theme.textSecondary)
                            }
                        }

                        labeled("What's contributing? (optional)") { TriggerChips(selected: $triggers) }

                        Toggle("Ate well today", isOn: $ateWell).tint(Theme.accent2)
                        Toggle("Exercised", isOn: $exercised).tint(Theme.accent2)

                        if exercised {
                            labeled("Duration (minutes)") {
                                TextField("30", text: $exerciseMinutes).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                            }
                            labeled("Intensity") {
                                Picker("Intensity", selection: $exerciseIntensity) {
                                    Text("—").tag("")
                                    Text("Light (e.g. a walk)").tag("light")
                                    Text("Moderate").tag("moderate")
                                    Text("Vigorous").tag("vigorous")
                                }
                                .pickerStyle(.menu)
                                .tint(Theme.accent)
                            }
                        }

                        labeled("Note (optional)") {
                            TextEditor(text: $note)
                                .frame(height: 90)
                                .scrollContentBackground(.hidden)
                                .background(Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        if existingId != nil {
                            Button("Delete", role: .destructive) { showDeleteConfirm = true }
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                }
            }
            .foregroundStyle(Theme.textPrimary)
            .navigationTitle(date == DateUtils.todayStr() ? "Today's Check-In" : "Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .dismissKeyboardToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear(perform: load)
            .confirmationDialog("Delete this check-in?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { deleteEntry() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes your \(Fmt.dateLong(date)) check-in entirely, including its note. This cannot be undone.")
            }
        }
    }

    private func labeled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(Theme.textSecondary)
            content()
        }
    }

    private func load() {
        guard let existing = store.data.checkins.first(where: { $0.date == date }) else { return }
        existingId = existing.id
        mood = existing.mood
        sleepHours = existing.sleepHours.map { String($0) } ?? ""
        craving = existing.craving ?? 0
        ateWell = existing.ateWell ?? false
        exercised = existing.exercised ?? false
        exerciseMinutes = existing.exerciseMinutes.map { String(Int($0)) } ?? ""
        exerciseIntensity = existing.exerciseIntensity ?? ""
        note = existing.note ?? ""
        triggers = existing.triggers
    }

    private func save() {
        var patch = CheckInPatch()
        patch.date = date
        patch.mood = .set(mood)
        patch.sleepHours = .set(Double(sleepHours))
        patch.craving = .set(craving)
        patch.ateWell = .set(ateWell)
        patch.exercised = .set(exercised)
        patch.exerciseMinutes = .set(exercised ? Double(exerciseMinutes) : nil)
        patch.exerciseIntensity = .set(exercised && !exerciseIntensity.isEmpty ? exerciseIntensity : nil)
        patch.note = .set(note)
        patch.triggers = .set(triggers)
        store.upsertCheckin(patch)
        dismiss()
    }

    private func deleteEntry() {
        if let id = store.data.checkins.first(where: { $0.date == date })?.id {
            store.deleteCheckin(id: id)
        }
        dismiss()
    }
}
