import SwiftUI

struct JournalView: View {
    @EnvironmentObject var store: Store
    @State private var selected: JournalEntry?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgApp.ignoresSafeArea()
                if store.data.journal.isEmpty {
                    VStack(spacing: 12) {
                        Text("No journal entries yet.").foregroundStyle(Theme.textSecondary)
                        Button("New Entry") { selected = nil; showEditor = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(store.data.journal) { entry in
                            Button {
                                selected = entry
                                showEditor = true
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(Fmt.moodEmoji(entry.mood))
                                        Text(entry.title.isEmpty ? "Untitled" : entry.title).font(.headline)
                                    }
                                    Text(Fmt.dateMedium(entry.date)).font(.caption2).foregroundStyle(Theme.textTertiary)
                                    Text(entry.body).font(.caption).foregroundStyle(Theme.textSecondary).lineLimit(2)
                                }
                            }
                            .listRowBackground(Theme.card)
                        }
                        .onDelete { indexSet in
                            for i in indexSet { store.deleteJournalEntry(id: store.data.journal[i].id) }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .foregroundStyle(Theme.textPrimary)
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selected = nil
                        showEditor = true
                    } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showEditor) {
                JournalEditorView(entry: selected).environmentObject(store)
            }
        }
    }
}

struct JournalEditorView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let entry: JournalEntry?

    @State private var title = ""
    @State private var body_ = ""
    @State private var mood: Int?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgApp.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    TextField("Title", text: $title)
                        .font(.title3.bold())
                        .textFieldStyle(.plain)
                    MoodPicker(mood: $mood)
                    TextEditor(text: $body_)
                        .scrollContentBackground(.hidden)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Spacer()
                }
                .padding()
            }
            .foregroundStyle(Theme.textPrimary)
            .navigationTitle(entry == nil ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear {
                if let entry {
                    title = entry.title
                    body_ = entry.body
                    mood = entry.mood
                }
            }
        }
    }

    private func save() {
        if let entry {
            store.updateJournalEntry(id: entry.id, title: title, body: body_, mood: mood)
        } else {
            store.addJournalEntry(title: title, body: body_, mood: mood)
        }
        dismiss()
    }
}
