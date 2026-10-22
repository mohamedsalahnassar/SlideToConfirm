#if canImport(SwiftUI)
import SwiftUI

/// How a ``HoldToConfirmButton`` shows that a hold is under way and how long is left.
///
/// Every style shows the same progress value; they differ in what moves. Styles that fill the
/// circle draw the icon twice, so it changes color exactly where the fill reaches.
public enum HoldToConfirmProgressStyle: String, Sendable, Hashable, CaseIterable, Identifiable {
    /// A ring around the circle fills clockwise. The most legible countdown. The default.
    case ring
    /// The ring is split into ticks that light up one by one, in step with the hold haptics.
    case segments
    /// The circle fills from the bottom up.
    case fill
    /// The circle fills from the bottom up with a moving wave on the surface.
    case liquid
    /// A disc grows from the center outward.
    case radial
    /// A sector sweeps clockwise, like a clock hand wiping the face.
    case pie
    /// Ripples radiate from the circle, faster as the hold nears the end, over a thin ring.
    case pulse
    /// A halo grows brighter and wider. The calmest style; time left is implied, not shown.
    case glow
    /// A comet orbits the circle, its tail growing with progress.
    case orbit
    /// The seconds left count down inside a ring. Suits long, deliberate holds.
    case countdown

    public var id: Self { self }

    /// Styles that fill the circle itself rather than drawing around it.
    var fillsCircle: Bool {
        switch self {
        case .fill, .liquid, .radial, .pie: return true
        default: return false
        }
    }

    /// Styles that draw a ring around the circle.
    var drawsRing: Bool {
        switch self {
        case .ring, .segments, .pulse, .orbit, .countdown: return true
        default: return false
        }
    }
}

/// How a ``HoldToConfirmButton`` celebrates once the action succeeds.
public enum HoldToConfirmCompletionStyle: String, Sendable, Hashable, CaseIterable, Identifiable {
    /// The circle turns green and a check mark draws itself in. The default.
    case checkmark
    /// A shock wave rings out from the circle.
    case ripple
    /// Particles burst outward.
    case burst
    /// The circle pops with an overshoot.
    case bounce
    /// The circle stretches into a capsule that spells out the success label.
    case morph
    /// The circle flips over to reveal the success face.
    case flip

    public var id: Self { self }
}

/// What happens to the progress when the person lets go early.
public enum HoldToConfirmReleaseBehavior: String, Sendable, Hashable, CaseIterable, Identifiable {
    /// Progress drains back, three times faster than it filled. Pressing again resumes from there.
    case drain
    /// Progress springs back to zero.
    case reset

    public var id: Self { self }
}

/// Where a ``HoldToConfirmButton`` shows its label relative to the circle.
public enum HoldToConfirmLabelPosition: String, Sendable, Hashable, CaseIterable, Identifiable {
    case below, above, leading, trailing
    /// No visible label. The label is still the accessibility label.
    case hidden

    public var id: Self { self }
}

/// A frozen state to render, for previews, galleries and snapshot tests.
public enum HoldToConfirmPreviewState: Sendable, Hashable {
    case idle
    /// Holding, `progress` of the way through the hold.
    case holding(progress: Double = 0.6)
    case processing
    case success
    case failure(message: String? = nil)
    case disabled

    var engineState: SlideToConfirmPreviewState {
        switch self {
        case .idle: return .idle
        case let .holding(progress): return .holding(progress: progress)
        case .processing: return .processing
        case .success: return .success
        case let .failure(message): return .failure(message: message)
        case .disabled: return .disabled
        }
    }
}

/// Every adjustable aspect of a ``HoldToConfirmButton``.
///
/// ```swift
/// HoldToConfirmButton("Hold to send", systemImage: "paperplane.fill") { try await send() }
///     .holdToConfirmConfiguration {
///         $0.progressStyle = .liquid
///         $0.completionStyle = .burst
///         $0.holdDuration = 1.5
///     }
/// ```
public struct HoldToConfirmConfiguration: Equatable {

    // MARK: Interaction

    /// How long the hold takes, in seconds. Default `1.2`.
    public var holdDuration: TimeInterval = 1.2

    /// How long a finger must rest before the hold starts, in seconds. Default `0.1`.
    /// Shorter than the slider's, since there is no drag to tell apart.
    public var holdDelay: TimeInterval = 0.1

    /// What happens to progress after an early release. Default ``HoldToConfirmReleaseBehavior/drain``.
    public var releaseBehavior: HoldToConfirmReleaseBehavior = .drain

    /// How many times faster than it filled the progress drains. Default `3`.
    public var drainSpeed: Double = 3

    /// How far, in points, a finger may stray outside the circle before the hold is cancelled. Default `24`.
    public var outsideTolerance: CGFloat = 24

    /// Whether a quick tap pulses the circle and shows the tap hint. Default `true`.
    public var hintsOnTap: Bool = true

    /// Delay between filling the circle and running the action, for keyboard and assistive
    /// activation, in seconds. Default `0.36`.
    public var activationDelay: TimeInterval = 0.36

    // MARK: Outcome

    /// What happens after the action succeeds. Default ``SlideToConfirmSuccessBehavior/remain``.
    public var successBehavior: SlideToConfirmSuccessBehavior = .remain

    /// How long the failure state shows before returning to idle, in seconds. Default `2`.
    public var failureDisplayDuration: TimeInterval = 2

    /// Whether the circle shakes when the action fails. Default `true`.
    public var shakesOnFailure: Bool = true

    // MARK: Size

    /// The circle's diameter, in points. Default `88`.
    public var diameter: CGFloat = 88

    /// The ring's line width, in points. Default `6`.
    public var ringWidth: CGFloat = 6

    /// The gap between the circle and the ring, in points. Default `5`.
    public var ringGap: CGFloat = 5

    /// The number of ticks for ``HoldToConfirmProgressStyle/segments``. Default `12`.
    public var segmentCount: Int = 12

    /// How much the circle shrinks under the finger. Default `0.94`.
    public var pressedScale: CGFloat = 0.94

    /// The icon's size relative to the diameter. Default `0.34`.
    public var iconScale: CGFloat = 0.34

    // MARK: Label

    /// Where the label sits. Default ``HoldToConfirmLabelPosition/below``.
    public var labelPosition: HoldToConfirmLabelPosition = .below

    /// A font for the label. `nil` builds a system font from ``labelSize`` and ``labelWeight``.
    public var labelFont: Font?

    /// The label's point size at the default text size. Default `15`.
    public var labelSize: CGFloat = 15

    /// The label's weight. Default `.semibold`.
    public var labelWeight: Font.Weight = .semibold

    /// The gap between the circle and the label, in points. Default `12`.
    public var labelSpacing: CGFloat = 12

    /// The largest Dynamic Type size the label follows. Default `.accessibility3`.
    public var maximumDynamicTypeSize: DynamicTypeSize = .accessibility3

    // MARK: Appearance and motion

    /// How the hold is shown. Default ``HoldToConfirmProgressStyle/ring``.
    public var progressStyle: HoldToConfirmProgressStyle = .ring

    /// How success is celebrated. Default ``HoldToConfirmCompletionStyle/checkmark``.
    public var completionStyle: HoldToConfirmCompletionStyle = .checkmark

    /// The icons in the circle for each phase.
    public var icons: SlideToConfirmIcons = SlideToConfirmIcons(idle: .systemImage("hand.tap.fill"))

    /// Colors for light and dark appearance. Shared with ``SlideToConfirm``.
    public var theme: SlideToConfirmTheme = .standard

    /// Whether the circle casts a shadow. Default `true`.
    public var showsShadow: Bool = true

    /// Opacity of a disabled control. Default `0.42`.
    public var disabledOpacity: Double = 0.42

    /// Animations for each kind of change.
    public var animations: SlideToConfirmAnimations = .default

    /// How many haptic ticks play during a hold. Default `3`.
    /// ``HoldToConfirmProgressStyle/segments`` lights one tick per segment regardless.
    public var holdHapticMarks: Int = 3

    public init() {}

    /// A copy with `transform` applied.
    public func with(_ transform: (inout HoldToConfirmConfiguration) -> Void) -> HoldToConfirmConfiguration {
        var copy = self
        transform(&copy)
        return copy
    }

    /// The width and height the circle and its ring occupy, before the label.
    public var outerDiameter: CGFloat { diameter + 2 * (ringGap + ringWidth) }
}

// MARK: - Presets

extension HoldToConfirmConfiguration {
    /// An 88 pt circle with a ring and a label below.
    public static var `default`: HoldToConfirmConfiguration { HoldToConfirmConfiguration() }

    /// A 56 pt circle, for toolbars and dense rows.
    public static var compact: HoldToConfirmConfiguration {
        HoldToConfirmConfiguration().with {
            $0.diameter = 56
            $0.ringWidth = 4
            $0.ringGap = 4
            $0.labelSize = 13
            $0.labelSpacing = 8
        }
    }

    /// A 128 pt circle, for a screen whose one job is this confirmation.
    public static var large: HoldToConfirmConfiguration {
        HoldToConfirmConfiguration().with {
            $0.diameter = 128
            $0.ringWidth = 8
            $0.ringGap = 7
            $0.labelSize = 17
            $0.labelSpacing = 16
        }
    }

    /// A 48 pt ring for an ordinary item in a 56 pt vertical bar, such as the trailing bar on
    /// iPhone Duo's outer display. The label is hidden; it remains the accessibility label.
    public static var verticalBar: HoldToConfirmConfiguration {
        HoldToConfirmConfiguration().with {
            $0.diameter = 36
            $0.ringWidth = 4
            $0.ringGap = 2
            $0.labelPosition = .hidden
            $0.iconScale = 0.4
            $0.showsShadow = false
        }
    }

    /// A destructive hold: red, filling from the bottom, two seconds long.
    public static var destructive: HoldToConfirmConfiguration {
        HoldToConfirmConfiguration().with {
            $0.theme = .destructive
            $0.progressStyle = .fill
            $0.holdDuration = 2
            $0.icons.idle = .systemImage("trash.fill")
        }
    }
}

// MARK: - Engine bridge

extension HoldToConfirmConfiguration {
    var engineSettings: ConfirmEngine.Settings {
        var settings = ConfirmEngine.Settings()
        settings.holdBehavior = releaseBehavior == .drain ? .fill : .glide
        settings.allowsDragging = false
        settings.holdDuration = holdDuration
        settings.holdDelay = holdDelay
        settings.fillDrainSpeed = drainSpeed
        // The view reports 0 while the finger is inside the circle and a large distance outside.
        settings.holdCancellationDistance = 1
        settings.dragActivationDistance = .greatestFiniteMagnitude
        settings.nudgesOnTap = hintsOnTap
        settings.nudgeDuration = 0.9
        settings.holdHapticMarks = progressStyle == .segments ? max(0, segmentCount - 1) : holdHapticMarks
        settings.activationDelay = activationDelay
        settings.failureDisplayDuration = failureDisplayDuration
        if case let .reset(after) = successBehavior {
            settings.successResetDelay = after
        }
        return settings
    }
}
#endif
