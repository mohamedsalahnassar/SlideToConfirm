#if canImport(SwiftUI)
import SwiftUI

/// The text a confirm control shows in each state.
///
/// Name the action, not the gesture, and keep each label short enough to sit beside the knob.
///
/// ```swift
/// SlideToConfirm(labels: SlideToConfirmLabels(
///     "Slide or hold to send",
///     armed: "Release to send",
///     holding: "Keep holding…",
///     processing: "Sending…",
///     success: "Sent",
///     failure: "Not sent · try again"
/// )) {
///     try await transfer.send()
/// }
/// ```
///
/// Labels you leave out use built-in text, localized into English, Arabic, French, German and Spanish.
public struct SlideToConfirmLabels {
    /// At rest. Also the control's accessibility label.
    public var idle: Text
    /// While a drag is past the commit threshold.
    public var armed: Text
    /// While holding.
    public var holding: Text
    /// While the action runs.
    public var processing: Text
    /// After the action succeeds.
    public var success: Text
    /// After the action fails, unless it threw a ``SlideToConfirmFailure`` with its own message.
    public var failure: Text
    /// The accessibility hint, read after the label.
    public var accessibilityHint: Text
    /// Shown briefly when someone taps a hold-only control instead of holding it.
    public var tapHint: Text

    /// Creates labels from localized string keys.
    ///
    /// - Parameters:
    ///   - idle: The resting label, such as "Slide to pay".
    ///   - tableName: The strings table to look keys up in. `nil` uses `Localizable`.
    ///   - bundle: The bundle to look keys up in. `nil` uses the main bundle.
    public init(
        _ idle: LocalizedStringKey,
        armed: LocalizedStringKey? = nil,
        holding: LocalizedStringKey? = nil,
        processing: LocalizedStringKey? = nil,
        success: LocalizedStringKey? = nil,
        failure: LocalizedStringKey? = nil,
        accessibilityHint: LocalizedStringKey? = nil,
        tapHint: LocalizedStringKey? = nil,
        tableName: String? = nil,
        bundle: Bundle? = nil
    ) {
        func text(_ key: LocalizedStringKey?) -> Text? {
            key.map { Text($0, tableName: tableName, bundle: bundle) }
        }
        self.init(
            idle: Text(idle, tableName: tableName, bundle: bundle),
            armed: text(armed),
            holding: text(holding),
            processing: text(processing),
            success: text(success),
            failure: text(failure),
            accessibilityHint: text(accessibilityHint),
            tapHint: text(tapHint)
        )
    }

    /// Creates labels from `Text` values, for verbatim or styled strings.
    public init(
        idle: Text,
        armed: Text? = nil,
        holding: Text? = nil,
        processing: Text? = nil,
        success: Text? = nil,
        failure: Text? = nil,
        accessibilityHint: Text? = nil,
        tapHint: Text? = nil
    ) {
        self.idle = idle
        self.armed = armed ?? Text("Release to confirm", bundle: .module)
        self.holding = holding ?? Text("Keep holding…", bundle: .module)
        self.processing = processing ?? Text("Processing…", bundle: .module)
        self.success = success ?? Text("Done", bundle: .module)
        self.failure = failure ?? Text("Failed · try again", bundle: .module)
        self.accessibilityHint = accessibilityHint ?? Text("Double-tap to confirm.", bundle: .module)
        self.tapHint = tapHint ?? Text("Press and hold", bundle: .module)
    }

    func text(for label: ConfirmSnapshot.Label, failureMessage: String?) -> Text {
        switch label {
        case .idle: return idle
        case .armed: return armed
        case .holding: return holding
        case .processing: return processing
        case .success: return success
        case .failure: return failureMessage.map { Text(verbatim: $0) } ?? failure
        }
    }
}
#endif
