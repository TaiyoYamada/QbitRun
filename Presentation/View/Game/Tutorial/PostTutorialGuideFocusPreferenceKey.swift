import SwiftUI

enum PostTutorialGuideFocusRegion: Hashable {
    case sphere
    case gatePalette
    case score
    case timer
}

struct PostTutorialGuideFocusPreferenceKey: PreferenceKey {
    typealias Value = [PostTutorialGuideFocusRegion: Anchor<CGRect>]
    static let defaultValue: Value = [:]

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { _, new in new }
    }
}
