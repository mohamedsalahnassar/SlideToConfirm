import Foundation

/// The lifecycle phase of a confirm control.
///
/// Every confirmation, whether it came from a drag, a hold, the keyboard or an
/// assistive technology, passes through the same phases:
/// `idle → processing → success` or `idle → processing → failure → idle`.
public enum SlideToConfirmPhase: Sendable, Hashable, CaseIterable {
    /// Waiting for the person to drag or hold.
    case idle
    /// The action is running. The control is locked so it can't fire twice.
    case processing
    /// The action finished successfully.
    case success
    /// The action threw. The control shows the failure label, then returns to ``idle``.
    case failure
}

/// What the person is doing with the control right now.
public enum SlideToConfirmInteraction: Sendable, Hashable, CaseIterable {
    /// Nobody is touching the control.
    case none
    /// A finger is down but hasn't yet been read as a drag or a hold.
    ///
    /// Lasts at most ``SlideToConfirmConfiguration/holdDelay``.
    case pending
    /// The knob follows the finger.
    case dragging
    /// The finger is still and the hold timer is running.
    case holding
}

/// How a confirmation was triggered. Passed to your action so analytics can tell the paths apart.
public enum SlideToConfirmTrigger: String, Sendable, Hashable, CaseIterable {
    /// The knob was dragged past the commit threshold and released.
    case drag
    /// The control was held until the hold timer completed.
    case hold
    /// A hold was started, then the person grabbed the knob and dragged it the rest of the way.
    case holdThenDrag
    /// VoiceOver, Switch Control, Voice Control or another assistive technology activated it.
    case accessibility
    /// Return or Space was pressed while the control had keyboard focus.
    case keyboard
}

/// What a still finger does to the control.
///
/// All behaviors share the same drag path. They differ only in what moves while the
/// person holds.
public enum SlideToConfirmHoldBehavior: String, Sendable, Hashable, CaseIterable {
    /// The knob glides to the end and a solid fill follows it. One progress value drives both.
    ///
    /// The label rides ahead of the knob, then hands over to a label on the fill.
    /// This is the recommended behavior.
    case combined
    /// The knob stays put and the track fills from the start edge. The label changes color
    /// as the fill passes it. On early release the fill drains back.
    ///
    /// The calmest option. Suits dense screens.
    case fill
    /// The knob glides by itself with the soft drag fill. Only the ring shows time left.
    case glide
    /// Holding does nothing. The control is slide-only.
    case none
}

/// A moment worth a haptic. Delivered to ``SlideToConfirmHaptics``.
public enum SlideToConfirmHapticEvent: Sendable, Hashable {
    /// A still finger turned into a hold.
    case holdBegan
    /// The hold passed a progress mark (for example 0.25, 0.5 and 0.75).
    case holdProgress(Double)
    /// A drag crossed the commit threshold. Releasing now confirms.
    case armed
    /// The control committed and the action is about to run.
    case confirmed
    /// The action succeeded.
    case success
    /// The action failed.
    case failure
}

/// A snapshot of the control, delivered to `onSlideToConfirmStateChange(_:)`.
public struct SlideToConfirmState: Sendable, Hashable {
    /// The lifecycle phase.
    public var phase: SlideToConfirmPhase
    /// What the person is doing right now.
    public var interaction: SlideToConfirmInteraction
    /// How close the control is to confirming, from 0 to 1.
    ///
    /// Follows the knob for drags and gliding holds, and the fill for ``SlideToConfirmHoldBehavior/fill``.
    public var progress: Double
    /// `true` while a drag is past the commit threshold, so releasing would confirm.
    public var isArmed: Bool
    /// `false` when the control is disabled.
    public var isEnabled: Bool

    public init(
        phase: SlideToConfirmPhase = .idle,
        interaction: SlideToConfirmInteraction = .none,
        progress: Double = 0,
        isArmed: Bool = false,
        isEnabled: Bool = true
    ) {
        self.phase = phase
        self.interaction = interaction
        self.progress = progress
        self.isArmed = isArmed
        self.isEnabled = isEnabled
    }

    /// A resting, enabled control.
    public static let idle = SlideToConfirmState()
}

/// A frozen state to render, for SwiftUI previews, design-system galleries and snapshot tests.
///
/// Apply it with `slideToConfirmPreviewState(_:)`. A control showing a preview state ignores touches.
public enum SlideToConfirmPreviewState: Sendable, Hashable {
    /// At rest.
    case idle
    /// Mid-drag, with the knob at `progress`.
    case dragging(progress: Double = 0.46)
    /// Dragged past the commit threshold. Releasing would confirm.
    case armed(progress: Double = 0.94)
    /// Holding, `progress` of the way through the hold.
    case holding(progress: Double = 0.76)
    /// The action is running.
    case processing
    /// The action succeeded.
    case success
    /// The action failed. Pass a `message` to override the failure label.
    case failure(message: String? = nil)
    /// Disabled, for example until a form is valid.
    case disabled
}

/// Throw this from your action to show a specific reason on the control.
///
/// ```swift
/// SlideToConfirm("Slide to pay") {
///     guard balance >= amount else {
///         throw SlideToConfirmFailure("Insufficient funds")
///     }
///     try await pay()
/// }
/// ```
///
/// Any other error shows the configured failure label.
/// Throwing `CancellationError` returns the control to idle quietly, with no failure haptic.
public struct SlideToConfirmFailure: Error, Sendable, Hashable, CustomStringConvertible {
    /// The text shown on the control in place of the failure label.
    public var message: String

    public init(_ message: String) {
        self.message = message
    }

    public var description: String { message }
}
