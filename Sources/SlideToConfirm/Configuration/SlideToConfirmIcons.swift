#if canImport(SwiftUI)
import SwiftUI

/// An icon drawn on the knob.
public enum SlideToConfirmIcon: Hashable, Sendable {
    /// A chevron pointing toward the end of the track. The default idle icon.
    case chevron
    /// An arrow pointing toward the end of the track.
    case arrow
    /// A check mark that draws itself in. The default success icon.
    case checkmark
    /// An exclamation mark in a circle. The default failure icon.
    case exclamationmark
    /// A spinning arc. The default processing icon.
    case spinner
    /// An SF Symbol.
    ///
    /// - Parameters:
    ///   - name: The symbol's name, such as `"lock.fill"`.
    ///   - followsDirection: Rotate and mirror the symbol with the slide direction, as for arrows.
    ///     Draw the symbol pointing right.
    case systemImage(String, followsDirection: Bool = false)
    /// No icon.
    case none

    /// `true` when the icon turns to point along the slide direction.
    var followsDirection: Bool {
        switch self {
        case .chevron, .arrow: return true
        case let .systemImage(_, followsDirection): return followsDirection
        case .checkmark, .exclamationmark, .spinner, .none: return false
        }
    }
}

/// The knob's icon in each phase.
public struct SlideToConfirmIcons: Hashable, Sendable {
    /// At rest and while dragging or holding.
    public var idle: SlideToConfirmIcon
    /// While the action runs.
    public var processing: SlideToConfirmIcon
    /// After the action succeeds.
    public var success: SlideToConfirmIcon
    /// After the action fails.
    public var failure: SlideToConfirmIcon

    public init(
        idle: SlideToConfirmIcon = .chevron,
        processing: SlideToConfirmIcon = .spinner,
        success: SlideToConfirmIcon = .checkmark,
        failure: SlideToConfirmIcon = .exclamationmark
    ) {
        self.idle = idle
        self.processing = processing
        self.success = success
        self.failure = failure
    }

    /// Chevron, spinner, check mark and exclamation mark.
    public static var `default`: SlideToConfirmIcons { SlideToConfirmIcons() }

    func icon(for kind: ConfirmSnapshot.KnobIcon) -> SlideToConfirmIcon {
        switch kind {
        case .idle: return idle
        case .processing: return processing
        case .success: return success
        case .failure: return failure
        }
    }
}

/// What a custom knob view knows about the control. See `slideToConfirmKnob(_:)`.
public struct SlideToConfirmKnobContext {
    /// The control's state.
    public var state: SlideToConfirmState
    /// The color the built-in icon would use right now. Follows inversion and success.
    public var iconColor: Color
    /// The knob's diameter, in points.
    public var diameter: CGFloat
    /// The slide direction.
    public var direction: SlideToConfirmDirection
}
#endif
