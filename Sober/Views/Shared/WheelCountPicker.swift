import SwiftUI

/// A labeled scroll-wheel picker over a small integer range — used for
/// "days per week" and "drinks per day" style fields, which are far more
/// natural to dial in on a wheel than to type into a text field.
struct WheelCountPicker: View {
    let title: String
    let range: ClosedRange<Int>
    /// When true, the top value in `range` is shown as "N+" (e.g. "5+")
    /// rather than a bare number, representing "this many or more."
    var plusAtMax: Bool = false
    @Binding var selection: Double

    private var current: Int {
        Int(selection.rounded()).clamped(to: range)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundStyle(Theme.textSecondary)
            Picker(title, selection: Binding(
                get: { current },
                set: { selection = Double($0) }
            )) {
                ForEach(range, id: \.self) { value in
                    Text(label(for: value)).tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .clipped()
        }
    }

    private func label(for value: Int) -> String {
        if plusAtMax && value == range.upperBound {
            return "\(value)+"
        }
        return "\(value)"
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
