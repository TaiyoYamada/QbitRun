import Foundation

extension String {
    var voiceOverFriendlyTutorialText: String {
        self
            .replacingOccurrences(of: "|0⟩", with: "ket zero")
            .replacingOccurrences(of: "|1⟩", with: "ket one")
            .replacingOccurrences(of: "|+⟩", with: "ket plus")
            .replacingOccurrences(of: "|−⟩", with: "ket minus")
            .replacingOccurrences(of: "|+i⟩", with: "ket plus i")
            .replacingOccurrences(of: "|−i⟩", with: "ket minus i")
            .replacingOccurrences(of: "↔", with: "to")
    }
}
