import SwiftUI

struct TriggerChips: View {
    @Binding var selected: [String]

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(Insights.triggerTags) { tag in
                let isOn = selected.contains(tag.id)
                Button {
                    if isOn { selected.removeAll { $0 == tag.id } } else { selected.append(tag.id) }
                } label: {
                    Text("\(tag.emoji) \(tag.label)")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isOn ? Theme.accent.opacity(0.22) : Theme.card)
                        .overlay(
                            Capsule().stroke(isOn ? Theme.accent : Theme.border, lineWidth: 1)
                        )
                        .foregroundStyle(isOn ? Theme.textPrimary : Theme.textSecondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// A simple wrapping horizontal-then-vertical layout for chip rows.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
