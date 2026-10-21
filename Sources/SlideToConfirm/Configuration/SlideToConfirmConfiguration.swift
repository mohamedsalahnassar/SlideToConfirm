#if canImport(SwiftUI)
import SwiftUI

/// The direction the knob travels to confirm.
public enum SlideToConfirmDirection: String, Sendable, Hashable, CaseIterable {
    /// From the leading edge to the trailing edge. Mirrors automatically in right-to-left layouts.
    case trailing
    /// From top to bottom. Suits a vertical bar, such as the tab zone on a trailing hardware edge.
    /// Never mirrors: down is down in every language.
    case down
    /// From bottom to top.
    case up

    /// `true` for ``down`` and ``up``.
    public var isVertical: Bool { self != .trailing }
}

/// What happens after the action succeeds.
public enum SlideToConfirmSuccessBehavior: Hashable, Sendable {
    /// Stay in the success state. Prevents a second confirmation; recreate the view (for example
    /// by changing its `id`) to start over. The default.
    case remain
    /// Return to idle after `after` seconds.
    case reset(after: TimeInterval)
}

/// Animations used for each kind of change.
public struct SlideToConfirmAnimations: Equatable {
    /// Springing back after an early release.
    public var springBack: Animation
    /// Snapping to the end on commit.
    public var snap: Animation
    /// The small hop that hints a tap should be a slide.
    public var nudge: Animation
    /// Color and label cross-fades, such as success and reset.
    public var transition: Animation
    /// Replaces all of the above when Reduce Motion is on. No overshoot.
    public var reducedMotion: Animation

    public init(
        springBack: Animation = .spring(response: 0.42, dampingFraction: 0.68),
        snap: Animation = .spring(response: 0.32, dampingFraction: 0.82),
        nudge: Animation = .spring(response: 0.22, dampingFraction: 0.55),
        transition: Animation = .easeInOut(duration: 0.25),
        reducedMotion: Animation = .easeOut(duration: 0.2)
    ) {
        self.springBack = springBack
        self.snap = snap
        self.nudge = nudge
        self.transition = transition
        self.reducedMotion = reducedMotion
    }

    public static var `default`: SlideToConfirmAnimations { SlideToConfirmAnimations() }
}

/// Every adjustable aspect of a ``SlideToConfirm`` control: interaction, timing, size,
/// typography, knob, colors and motion.
///
/// Set it for a view hierarchy with `slideToConfirmConfiguration(_:)`, or adjust the inherited
/// value with the closure variant:
///
/// ```swift
/// SlideToConfirm("Slide or hold to send") { try await send() }
///     .slideToConfirmConfiguration {
///         $0.holdBehavior = .fill
///         $0.holdDuration = 2
///         $0.theme = .tinted(.green)
///     }
/// ```
public struct SlideToConfirmConfiguration: Equatable {

    // MARK: Interaction

    /// The direction the knob travels. Default ``SlideToConfirmDirection/trailing``.
    public var direction: SlideToConfirmDirection = .trailing

    /// What a still finger does. Default ``SlideToConfirmHoldBehavior/combined``.
    public var holdBehavior: SlideToConfirmHoldBehavior = .combined

    /// Whether the knob can be dragged. Turn off, with a hold behavior, for a hold-only control.
    public var allowsDragging: Bool = true

    /// How far, from 0 to 1, a drag must go before releasing confirms. Default `0.9`.
    public var commitThreshold: Double = 0.9

    /// How long a hold takes from start to end, in seconds. Default `1.2`.
    public var holdDuration: TimeInterval = 1.2

    /// How long a finger must stay still before it counts as a hold, in seconds. Default `0.18`.
    ///
    /// During this window a move along the track on the knob starts a drag instead.
    public var holdDelay: TimeInterval = 0.18

    /// How far, in points, a finger on the knob must move along the track to start a drag. Default `6`.
    public var dragActivationDistance: CGFloat = 6

    /// How far, in points, a holding finger may wander. Default `12`.
    ///
    /// Beyond it, a finger on the knob takes over and drags; a finger elsewhere cancels.
    public var holdCancellationDistance: CGFloat = 12

    /// How many times faster than it filled the fill drains after an early release,
    /// for ``SlideToConfirmHoldBehavior/fill``. Default `3`.
    public var fillDrainSpeed: Double = 3

    /// Whether a quick tap nudges the knob to hint that it slides. Default `true`.
    public var nudgesOnTap: Bool = true

    /// Delay between the knob snapping to the end and the action running, when confirmed by the
    /// keyboard or an assistive technology, in seconds. Default `0.36`.
    public var activationDelay: TimeInterval = 0.36

    // MARK: Outcome

    /// What happens after the action succeeds. Default ``SlideToConfirmSuccessBehavior/remain``.
    public var successBehavior: SlideToConfirmSuccessBehavior = .remain

    /// How long the failure label shows before returning to idle, in seconds. Default `2`.
    /// Touching the control during this time retries straight away.
    public var failureDisplayDuration: TimeInterval = 2

    /// Whether the control shakes when the action fails. Default `true`.
    public var shakesOnFailure: Bool = true

    // MARK: Size

    /// The track's height, or its width for vertical directions, in points. Default `60`.
    ///
    /// Grows at accessibility text sizes when ``growsWithDynamicType`` is on.
    public var thickness: CGFloat = 60

    /// The gap between the knob and the track edge, in points. Default `4`.
    public var knobInset: CGFloat = 4

    /// The longest the track grows along its direction, in points. Default `440`, so the control
    /// fills a phone but stays a comfortable size on iPad and Mac. `nil` lets it fill any width.
    public var maxLength: CGFloat? = 440

    /// The length used when the container doesn't propose one, such as in a scroll view. Default `320`.
    public var idealLength: CGFloat = 320

    /// The corner radius of the track. `nil`, the default, makes a capsule.
    public var cornerRadius: CGFloat?

    /// Whether the track gets thicker to fit the label at accessibility text sizes. Default `true`.
    public var growsWithDynamicType: Bool = true

    /// The largest Dynamic Type size the label follows. Default `.accessibility3`.
    public var maximumDynamicTypeSize: DynamicTypeSize = .accessibility3

    // MARK: Label

    /// A font for the label. `nil`, the default, uses the system font built from
    /// ``labelSize``, ``labelWeight`` and ``labelDesign``, scaled with Dynamic Type.
    public var labelFont: Font?

    /// The label's point size at the default text size. Default `15`.
    public var labelSize: CGFloat = 15

    /// The label's weight. Default `.semibold`.
    public var labelWeight: Font.Weight = .semibold

    /// The label's design. Default `.default`.
    public var labelDesign: Font.Design = .default

    /// Letter spacing for the label, in points. Default `-0.15`.
    public var labelTracking: CGFloat = -0.15

    /// The gap between the label and the end of the track, in points. Default `20`.
    public var labelEdgePadding: CGFloat = 20

    /// The gap between the label and the knob, in points. Default `6`.
    public var labelKnobSpacing: CGFloat = 6

    /// Whether the idle label shimmers toward the end. Off automatically with Reduce Motion. Default `true`.
    public var shimmer: Bool = true

    /// Seconds per shimmer cycle. Default `2.4`.
    public var shimmerDuration: TimeInterval = 2.4

    // MARK: Knob

    /// The icons shown on the knob in each phase.
    public var icons: SlideToConfirmIcons = .default

    /// Whether a countdown ring shows on the knob while holding. Default `true`.
    public var showsHoldRing: Bool = true

    /// The countdown ring's line width, in points. Default `2.5`.
    public var ringLineWidth: CGFloat = 2.5

    /// How much the knob grows once a drag passes the commit threshold. Default `1.05`.
    public var armedKnobScale: CGFloat = 1.05

    // MARK: Appearance

    /// Colors for light and dark appearance. Default ``SlideToConfirmTheme/standard``.
    public var theme: SlideToConfirmTheme = .standard

    /// Opacity of a disabled control. Default `0.42`.
    public var disabledOpacity: Double = 0.42

    // MARK: Motion and haptics

    /// Animations for each kind of change.
    public var animations: SlideToConfirmAnimations = .default

    /// How many haptic ticks play during a hold, evenly spaced. Default `3` (at 25, 50 and 75%).
    public var holdHapticMarks: Int = 3

    /// Creates the default configuration.
    public init() {}

    /// A copy with `transform` applied.
    ///
    /// ```swift
    /// .slideToConfirmConfiguration(.compact.with { $0.theme = .destructive })
    /// ```
    public func with(_ transform: (inout SlideToConfirmConfiguration) -> Void) -> SlideToConfirmConfiguration {
        var copy = self
        transform(&copy)
        return copy
    }
}

// MARK: - Presets

extension SlideToConfirmConfiguration {
    /// The defaults: a 60 pt combined slide-or-hold control, capped at 440 pt.
    public static var `default`: SlideToConfirmConfiguration { SlideToConfirmConfiguration() }

    /// A 48 pt track with a 14 pt label, for dense layouts.
    public static var compact: SlideToConfirmConfiguration {
        SlideToConfirmConfiguration().with {
            $0.thickness = 48
            $0.labelSize = 14
            $0.labelEdgePadding = 16
        }
    }

    /// A 72 pt track with a 17 pt label, for hero placements.
    public static var large: SlideToConfirmConfiguration {
        SlideToConfirmConfiguration().with {
            $0.thickness = 72
            $0.knobInset = 5
            $0.labelSize = 17
        }
    }

    /// A 56 pt pull-down track sized to replace a vertical tab bar, for example on a device's
    /// trailing vertical bar. Give it a height of about 300 pt.
    public static var verticalBar: SlideToConfirmConfiguration {
        SlideToConfirmConfiguration().with {
            $0.direction = .down
            $0.thickness = 56
            $0.labelSize = 14
            $0.idealLength = 300
        }
    }

    /// Drag only. Holding does nothing.
    public static var slideOnly: SlideToConfirmConfiguration {
        SlideToConfirmConfiguration().with {
            $0.holdBehavior = .none
        }
    }

    /// Hold only: the knob can't be dragged and the track fills while held.
    public static var holdOnly: SlideToConfirmConfiguration {
        SlideToConfirmConfiguration().with {
            $0.holdBehavior = .fill
            $0.allowsDragging = false
            $0.icons.idle = .systemImage("hand.tap.fill")
        }
    }
}

// MARK: - Engine bridge

extension SlideToConfirmConfiguration {
    var engineSettings: ConfirmEngine.Settings {
        var settings = ConfirmEngine.Settings()
        settings.holdBehavior = holdBehavior
        settings.allowsDragging = allowsDragging
        settings.holdDuration = holdDuration
        settings.holdDelay = holdDelay
        settings.commitThreshold = commitThreshold
        settings.dragActivationDistance = Double(dragActivationDistance)
        settings.holdCancellationDistance = Double(holdCancellationDistance)
        settings.fillDrainSpeed = fillDrainSpeed
        settings.nudgesOnTap = nudgesOnTap
        settings.holdHapticMarks = holdHapticMarks
        settings.activationDelay = activationDelay
        settings.failureDisplayDuration = failureDisplayDuration
        if case let .reset(after) = successBehavior {
            settings.successResetDelay = after
        }
        return settings
    }
}
#endif
