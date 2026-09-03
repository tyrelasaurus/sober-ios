import SwiftUI

struct MoodPicker: View {
    @Binding var mood: Int?

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { score in
                Button {
                    mood = (mood == score) ? nil : score
                } label: {
                    Text(Fmt.moodEmoji(score))
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(mood == score ? Theme.accent.opacity(0.25) : Theme.card)
                        .overlay(
                            Circle().stroke(mood == score ? Theme.accent : Theme.border, lineWidth: mood == score ? 2 : 1)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
