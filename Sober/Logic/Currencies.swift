import Foundation

struct CurrencyOption: Identifiable, Equatable {
    let code: String
    let symbol: String
    let name: String
    var id: String { code }
}

enum Currencies {
    /// A curated list of widely-used currencies. Symbols are disambiguated
    /// (e.g. "C$" vs "A$" vs "$") since several currencies otherwise share
    /// the same bare "$" glyph, and only one symbol string is stored.
    static let common: [CurrencyOption] = [
        .init(code: "USD", symbol: "$", name: "US Dollar"),
        .init(code: "EUR", symbol: "€", name: "Euro"),
        .init(code: "GBP", symbol: "£", name: "British Pound"),
        .init(code: "JPY", symbol: "¥", name: "Japanese Yen"),
        .init(code: "CAD", symbol: "C$", name: "Canadian Dollar"),
        .init(code: "AUD", symbol: "A$", name: "Australian Dollar"),
        .init(code: "NZD", symbol: "NZ$", name: "New Zealand Dollar"),
        .init(code: "CHF", symbol: "Fr.", name: "Swiss Franc"),
        .init(code: "CNY", symbol: "¥", name: "Chinese Yuan"),
        .init(code: "INR", symbol: "₹", name: "Indian Rupee"),
        .init(code: "KRW", symbol: "₩", name: "South Korean Won"),
        .init(code: "MXN", symbol: "Mex$", name: "Mexican Peso"),
        .init(code: "BRL", symbol: "R$", name: "Brazilian Real"),
        .init(code: "SEK", symbol: "kr", name: "Swedish Krona"),
        .init(code: "NOK", symbol: "kr", name: "Norwegian Krone"),
        .init(code: "ZAR", symbol: "R", name: "South African Rand"),
        .init(code: "SGD", symbol: "S$", name: "Singapore Dollar"),
        .init(code: "HKD", symbol: "HK$", name: "Hong Kong Dollar"),
    ]

    static func option(forCode code: String) -> CurrencyOption {
        common.first { $0.code == code } ?? common[0]
    }

    /// Best-effort match for data that predates this picker (a free-typed
    /// symbol with no associated code) — falls back to USD if unrecognized.
    static func option(forSymbol symbol: String) -> CurrencyOption {
        common.first { $0.symbol == symbol } ?? common[0]
    }
}
