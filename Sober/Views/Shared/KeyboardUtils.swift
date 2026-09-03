import SwiftUI
import UIKit

/// SwiftUI's decimal/number-pad keyboards have no Return key, so there's
/// otherwise no way to dismiss them and move on to the next field. This adds
/// a standard "Done" button in the accessory bar above the keyboard.
extension View {
    func dismissKeyboardToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}
