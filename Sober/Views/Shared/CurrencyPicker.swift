import SwiftUI

/// Picks from a curated list of world currencies instead of free-text
/// keyboard entry — sets both the currency code and its display symbol.
struct CurrencyPicker: View {
    @Binding var currencyCode: String
    @Binding var currencySymbol: String

    var body: some View {
        Picker(selection: Binding(
            get: { currencyCode },
            set: { newCode in
                currencyCode = newCode
                currencySymbol = Currencies.option(forCode: newCode).symbol
            }
        )) {
            ForEach(Currencies.common) { option in
                Text("\(option.symbol)  \(option.name) (\(option.code))").tag(option.code)
            }
        } label: {
            Text("Currency")
        }
        .pickerStyle(.menu)
        .tint(Theme.accent)
    }
}
