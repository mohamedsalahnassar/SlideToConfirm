#if canImport(SwiftUI)
import SwiftUI

/// The alert shown before confirming when an assistive technology activates the control.
struct SlideToConfirmAccessibilityAlert {
    var title: Text
    var message: Text?
    var confirm: Text
    var cancel: Text
}

struct SlideToConfirmKnobBuilder {
    let build: (SlideToConfirmKnobContext) -> AnyView
}

private struct ConfigurationKey: EnvironmentKey {
    static var defaultValue: SlideToConfirmConfiguration { SlideToConfirmConfiguration() }
}

private struct HapticsKey: EnvironmentKey {
    static var defaultValue: SlideToConfirmHaptics { .automatic }
}

private struct PreviewStateKey: EnvironmentKey {
    static var defaultValue: SlideToConfirmPreviewState? { nil }
}

private struct StateHandlerKey: EnvironmentKey {
    static var defaultValue: ((SlideToConfirmState) -> Void)? { nil }
}

private struct KnobBuilderKey: EnvironmentKey {
    static var defaultValue: SlideToConfirmKnobBuilder? { nil }
}

private struct AccessibilityAlertKey: EnvironmentKey {
    static var defaultValue: SlideToConfirmAccessibilityAlert? { nil }
}

extension EnvironmentValues {
    /// The configuration confirm controls in this environment use.
    public var slideToConfirmConfiguration: SlideToConfirmConfiguration {
        get { self[ConfigurationKey.self] }
        set { self[ConfigurationKey.self] = newValue }
    }

    var slideToConfirmHaptics: SlideToConfirmHaptics {
        get { self[HapticsKey.self] }
        set { self[HapticsKey.self] = newValue }
    }

    var slideToConfirmPreviewState: SlideToConfirmPreviewState? {
        get { self[PreviewStateKey.self] }
        set { self[PreviewStateKey.self] = newValue }
    }

    var slideToConfirmStateHandler: ((SlideToConfirmState) -> Void)? {
        get { self[StateHandlerKey.self] }
        set { self[StateHandlerKey.self] = newValue }
    }

    var slideToConfirmKnobBuilder: SlideToConfirmKnobBuilder? {
        get { self[KnobBuilderKey.self] }
        set { self[KnobBuilderKey.self] = newValue }
    }

    var slideToConfirmAccessibilityAlert: SlideToConfirmAccessibilityAlert? {
        get { self[AccessibilityAlertKey.self] }
        set { self[AccessibilityAlertKey.self] = newValue }
    }
}

extension View {
    /// Sets the configuration for confirm controls in this view.
    public func slideToConfirmConfiguration(_ configuration: SlideToConfirmConfiguration) -> some View {
        environment(\.slideToConfirmConfiguration, configuration)
    }

    /// Adjusts the inherited configuration for confirm controls in this view.
    ///
    /// ```swift
    /// .slideToConfirmConfiguration {
    ///     $0.holdDuration = 2
    ///     $0.theme = .destructive
    /// }
    /// ```
    public func slideToConfirmConfiguration(
        _ transform: @escaping (inout SlideToConfirmConfiguration) -> Void
    ) -> some View {
        transformEnvironment(\.slideToConfirmConfiguration, transform: transform)
    }

    /// Sets the colors of confirm controls in this view.
    public func slideToConfirmTheme(_ theme: SlideToConfirmTheme) -> some View {
        transformEnvironment(\.slideToConfirmConfiguration) { $0.theme = theme }
    }

    /// Sets the direction the knob travels in confirm controls in this view.
    public func slideToConfirmDirection(_ direction: SlideToConfirmDirection) -> some View {
        transformEnvironment(\.slideToConfirmConfiguration) { $0.direction = direction }
    }

    /// Sets what a still finger does on confirm controls in this view.
    public func slideToConfirmHoldBehavior(_ holdBehavior: SlideToConfirmHoldBehavior) -> some View {
        transformEnvironment(\.slideToConfirmConfiguration) { $0.holdBehavior = holdBehavior }
    }

    /// Sets how confirm controls in this view play haptics.
    public func slideToConfirmHaptics(_ haptics: SlideToConfirmHaptics) -> some View {
        environment(\.slideToConfirmHaptics, haptics)
    }

    /// Freezes confirm controls in this view in `state`, for previews, galleries and snapshot tests.
    ///
    /// A frozen control ignores touches. Pass `nil` to make it live again.
    public func slideToConfirmPreviewState(_ state: SlideToConfirmPreviewState?) -> some View {
        environment(\.slideToConfirmPreviewState, state)
    }

    /// Replaces the knob's icon with your own view.
    ///
    /// ```swift
    /// .slideToConfirmKnob { knob in
    ///     Image(systemName: knob.state.phase == .success ? "lock.open.fill" : "lock.fill")
    ///         .foregroundStyle(knob.iconColor)
    /// }
    /// ```
    ///
    /// The knob's shape, color, shadow and countdown ring stay.
    public func slideToConfirmKnob<Content: View>(
        @ViewBuilder _ content: @escaping (SlideToConfirmKnobContext) -> Content
    ) -> some View {
        environment(\.slideToConfirmKnobBuilder, SlideToConfirmKnobBuilder { AnyView(content($0)) })
    }

    /// Asks for confirmation in an alert when VoiceOver, Switch Control or Voice Control activates
    /// a confirm control in this view, so there is still a second step for consequential actions.
    ///
    /// Touch, drag and keyboard confirmations are not affected.
    public func slideToConfirmAccessibilityAlert(
        _ title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        confirmLabel: LocalizedStringKey? = nil,
        cancelLabel: LocalizedStringKey? = nil
    ) -> some View {
        environment(\.slideToConfirmAccessibilityAlert, SlideToConfirmAccessibilityAlert(
            title: Text(title),
            message: message.map { Text($0) },
            confirm: confirmLabel.map { Text($0) } ?? Text("Confirm", bundle: .module),
            cancel: cancelLabel.map { Text($0) } ?? Text("Cancel", bundle: .module)
        ))
    }

    /// Calls `action` whenever a confirm control in this view changes state, including every frame
    /// of progress while dragging or holding.
    public func onSlideToConfirmStateChange(_ action: @escaping (SlideToConfirmState) -> Void) -> some View {
        environment(\.slideToConfirmStateHandler, action)
    }
}

extension View {
    /// `onChange(of:)` without the iOS 17 deprecation.
    @ViewBuilder
    func stcOnChange<V: Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View {
        if #available(iOS 17, macOS 14, *) {
            onChange(of: value) { _, newValue in action(newValue) }
        } else {
            onChange(of: value, perform: action)
        }
    }
}
#endif
