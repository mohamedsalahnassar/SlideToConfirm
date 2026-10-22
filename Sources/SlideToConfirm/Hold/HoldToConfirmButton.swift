#if canImport(SwiftUI)
import SwiftUI

/// A circular button that confirms when the person presses and holds it.
///
/// ```swift
/// HoldToConfirmButton("Hold to send", systemImage: "paperplane.fill") {
///     try await transfer.send()
/// }
/// ```
///
/// The circle is the compact sibling of ``SlideToConfirm``: the same engine, haptics, labels,
/// themes, outcomes and accessibility, without the track. It fits where a pill can't, such as a
/// floating corner, a toolbar or a 56 pt vertical bar.
///
/// - **Hold**: after ``HoldToConfirmConfiguration/holdDelay`` the progress style starts; at the end
///   the circle commits, plays the confirm haptic and runs your action.
/// - **Let go early**: progress drains back (or resets), and pressing again picks up from there.
/// - **Slide off**: moving the finger well outside the circle cancels, like any button.
/// - **Tap**: the circle pulses and shows the tap hint, so people learn to hold.
/// - **Keyboard and assistive technologies**: it's a button named after its label.
public struct HoldToConfirmButton: View {
    private let labels: SlideToConfirmLabels
    private let systemImage: String?
    private let action: @MainActor (SlideToConfirmTrigger) async throws -> Void

    @Environment(\.holdToConfirmConfiguration) private var baseConfiguration
    @Environment(\.slideToConfirmHaptics) private var haptics
    @Environment(\.holdToConfirmPreviewState) private var previewState
    @Environment(\.holdToConfirmStateHandler) private var stateHandler
    @Environment(\.slideToConfirmAccessibilityAlert) private var accessibilityAlert
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var engine = ConfirmEngine()
    @State private var reporter = StateReporter()
    @State private var shakes = 0
    @State private var celebration: CGFloat = 0
    @State private var morphLabelWidth: CGFloat = 0
    @State private var isGestureActive = false
    @State private var isShowingAccessibilityAlert = false
    @GestureState private var isTouching = false

    // MARK: Initializers

    /// Creates a button with labels for every state, an optional SF Symbol, and an action that
    /// learns how it was confirmed.
    ///
    /// - Parameters:
    ///   - labels: The text for each state. ``SlideToConfirmLabels/tapHint`` shows after a tap.
    ///   - systemImage: The SF Symbol in the circle. `nil` uses the configured idle icon.
    ///   - action: Runs on confirm. Throw to show failure.
    public init(
        labels: SlideToConfirmLabels,
        systemImage: String? = nil,
        action: @escaping @MainActor (SlideToConfirmTrigger) async throws -> Void
    ) {
        self.labels = labels
        self.systemImage = systemImage
        self.action = action
    }

    /// Creates a button with labels for every state and an optional SF Symbol.
    public init(
        labels: SlideToConfirmLabels,
        systemImage: String? = nil,
        action: @escaping @MainActor () async throws -> Void
    ) {
        self.init(labels: labels, systemImage: systemImage, action: { @MainActor _ in try await action() })
    }

    /// Creates a button with a localized label and built-in labels for the other states.
    public init(
        _ titleKey: LocalizedStringKey,
        systemImage: String? = nil,
        action: @escaping @MainActor () async throws -> Void
    ) {
        self.init(labels: SlideToConfirmLabels(titleKey), systemImage: systemImage, action: action)
    }

    /// Creates a button with a localized label, and an action that learns how it was confirmed.
    public init(
        _ titleKey: LocalizedStringKey,
        systemImage: String? = nil,
        action: @escaping @MainActor (SlideToConfirmTrigger) async throws -> Void
    ) {
        self.init(labels: SlideToConfirmLabels(titleKey), systemImage: systemImage, action: action)
    }

    /// Creates a button with a verbatim label.
    @_disfavoredOverload
    public init<S: StringProtocol>(
        _ title: S,
        systemImage: String? = nil,
        action: @escaping @MainActor () async throws -> Void
    ) {
        self.init(labels: SlideToConfirmLabels(idle: Text(title)), systemImage: systemImage, action: action)
    }

    /// Creates a button with a verbatim label, and an action that learns how it was confirmed.
    @_disfavoredOverload
    public init<S: StringProtocol>(
        _ title: S,
        systemImage: String? = nil,
        action: @escaping @MainActor (SlideToConfirmTrigger) async throws -> Void
    ) {
        self.init(labels: SlideToConfirmLabels(idle: Text(title)), systemImage: systemImage, action: action)
    }

    // MARK: Body

    public var body: some View {
        let configuration = self.configuration
        layout(configuration)
            .modifier(ShakeEffect(animatableData: CGFloat(shakes)))
            .stcOnChange(of: isTouching) { touching in
                guard !touching, isGestureActive else { return }
                isGestureActive = false
                perform { $0.touchCancelled(at: $1) }
            }
            .stcOnChange(of: isEnabled) { enabled in
                perform { $0.setEnabled(enabled, at: $1) }
            }
            .stcOnChange(of: configuration.engineSettings) { settings in
                engine.updateSettings(settings)
            }
            .stcOnChange(of: displayedEngine.phase == .success) { succeeded in
                celebrate(succeeded, style: configuration.completionStyle)
            }
            .onAppear {
                engine.updateSettings(configuration.engineSettings)
                if !isEnabled { perform { $0.setEnabled(false, at: $1) } }
            }
            .task(id: previewState == nil ? engine.nextDeadline : nil) {
                await runNextDeadline()
            }
            .task(id: previewState == nil && engine.isTimeDependent) {
                await reportProgressWhileTimeDependent()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(labels.idle)
            .accessibilityValue(accessibilityValue)
            .accessibilityHint(displayedEngine.phase == .idle ? labels.accessibilityHint : Text(verbatim: ""))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { activateFromAccessibility() }
            .modifier(KeyboardActivation(isEnabled: isEnabled && previewState == nil) {
                perform { $0.activate(.keyboard, at: $1) }
            })
            .alert(
                accessibilityAlert?.title ?? Text(verbatim: ""),
                isPresented: $isShowingAccessibilityAlert
            ) {
                Button(role: .cancel) {} label: {
                    accessibilityAlert?.cancel ?? Text("Cancel", bundle: .module)
                }
                Button {
                    perform { $0.activate(.accessibility, at: $1) }
                } label: {
                    accessibilityAlert?.confirm ?? Text("Confirm", bundle: .module)
                }
            } message: {
                if let message = accessibilityAlert?.message {
                    message
                }
            }
    }

    @ViewBuilder
    private func layout(_ configuration: HoldToConfirmConfiguration) -> some View {
        switch configuration.labelPosition {
        case .below:
            VStack(spacing: configuration.labelSpacing) { circle(configuration); caption(configuration, alignment: .center) }
        case .above:
            VStack(spacing: configuration.labelSpacing) { caption(configuration, alignment: .center); circle(configuration) }
        case .leading:
            HStack(spacing: configuration.labelSpacing) { caption(configuration, alignment: .trailing); circle(configuration) }
        case .trailing:
            HStack(spacing: configuration.labelSpacing) { circle(configuration); caption(configuration, alignment: .leading) }
        case .hidden:
            circle(configuration)
        }
    }

    private func circle(_ configuration: HoldToConfirmConfiguration) -> some View {
        let displayed = displayedEngine
        let isPreview = previewState != nil
        let outer = configuration.outerDiameter
        return TimelineView(.animation(minimumInterval: nil, paused: !displayed.isTimeDependent)) { context in
            HoldCircleRenderer(
                celebration: isPreview ? 1 : celebration,
                snapshot: resolvedSnapshot(displayed, at: context.date),
                configuration: configuration,
                palette: configuration.theme.palette(for: colorScheme),
                successLabel: labels.success,
                labelFont: labelFont(configuration),
                morphLabelWidth: morphLabelWidth,
                isAnimated: !isPreview && !reduceMotion
            )
        }
        .frame(width: outer, height: outer)
        .contentShape(Circle())
        .gesture(holdGesture(outer: outer, tolerance: configuration.outsideTolerance), including: isPreview ? .none : .all)
        .onPreferenceChange(MorphLabelWidthKey.self) { morphLabelWidth = $0 }
    }

    private func caption(_ configuration: HoldToConfirmConfiguration, alignment: TextAlignment) -> some View {
        let displayed = displayedEngine
        let palette = configuration.theme.palette(for: colorScheme)
        let isFailure = displayed.phase == .failure
        return captionText(displayed)
            .font(labelFont(configuration))
            .foregroundStyle(isFailure ? palette.failureLabel : palette.label)
            .multilineTextAlignment(alignment)
            .fixedSize(horizontal: false, vertical: true)
            .id(captionKey(displayed))
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.18), value: captionKey(displayed))
    }

    // MARK: Derived values

    /// The environment's configuration with this button's SF Symbol applied.
    private var configuration: HoldToConfirmConfiguration {
        var configuration = baseConfiguration
        if let systemImage { configuration.icons.idle = .systemImage(systemImage) }
        return configuration
    }

    private var displayedEngine: ConfirmEngine {
        guard let previewState else { return engine }
        return ConfirmEngine.preview(previewState.engineState, settings: configuration.engineSettings)
    }

    private func resolvedSnapshot(_ engine: ConfirmEngine, at date: Date) -> ConfirmSnapshot {
        var snapshot = engine.snapshot(at: date.timeIntervalSinceReferenceDate)
        if !isEnabled { snapshot.isEnabled = false }
        return snapshot
    }

    private func labelFont(_ configuration: HoldToConfirmConfiguration) -> Font {
        let scale = min(dynamicTypeSize, configuration.maximumDynamicTypeSize).stcBodyScale
        return configuration.labelFont ?? .system(size: configuration.labelSize * scale, weight: configuration.labelWeight)
    }

    private func captionText(_ engine: ConfirmEngine) -> Text {
        switch engine.phase {
        case .processing: return labels.processing
        case .success: return labels.success
        case .failure: return labels.text(for: .failure, failureMessage: engine.failureMessage)
        case .idle:
            switch engine.interaction {
            case .holding: return labels.holding
            case .nudging: return labels.tapHint
            case .none, .pending, .dragging: return labels.idle
            }
        }
    }

    private func captionKey(_ engine: ConfirmEngine) -> String {
        switch engine.phase {
        case .idle:
            switch engine.interaction {
            case .holding: return "holding"
            case .nudging: return "hint"
            default: return "idle"
            }
        case .processing: return "processing"
        case .success: return "success"
        case .failure: return "failure"
        }
    }

    private var accessibilityValue: Text {
        let shown = displayedEngine
        switch shown.phase {
        case .idle: return Text(verbatim: "")
        case .processing: return labels.processing
        case .success: return labels.success
        case .failure: return labels.text(for: .failure, failureMessage: shown.failureMessage)
        }
    }

    // MARK: Gesture

    private func holdGesture(outer: CGFloat, tolerance: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .updating($isTouching) { _, isTouching, _ in isTouching = true }
            .onChanged { value in
                if !isGestureActive {
                    isGestureActive = true
                    haptics.prepare?()
                    perform { $0.touchDown(onKnob: false, travel: 1, at: $1) }
                }
                // Inside the circle (plus tolerance) counts as still; outside cancels the hold.
                let offset = hypot(value.location.x - outer / 2, value.location.y - outer / 2)
                let isOutside = offset > outer / 2 + tolerance
                perform { $0.touchMoved(along: 0, distance: isOutside ? 1000 : 0, at: $1) }
            }
            .onEnded { _ in
                guard isGestureActive else { return }
                isGestureActive = false
                perform { $0.touchUp(at: $1) }
            }
    }

    // MARK: Engine

    private func perform(_ change: (inout ConfirmEngine, TimeInterval) -> ConfirmEngine.Update) {
        guard previewState == nil else { return }
        let configuration = self.configuration
        let now = Date().timeIntervalSinceReferenceDate
        var next = engine
        next.updateSettings(configuration.engineSettings)
        let wasFailure = next.phase == .failure
        let update = change(&next, now)

        if let animation = animation(for: update.animation, configuration: configuration) {
            withAnimation(animation) { engine = next }
        } else {
            engine = next
        }
        reporter.report(next.snapshot(at: now).publicState(isEnabled: isEnabled), to: stateHandler)

        if !wasFailure, next.phase == .failure, configuration.shakesOnFailure, !reduceMotion {
            withAnimation(.linear(duration: 0.42)) { shakes += 1 }
        }

        for effect in update.effects {
            switch effect {
            case let .haptic(event):
                haptics.play?(event)
            case let .confirm(trigger):
                run(trigger)
            }
        }
    }

    private func animation(for kind: ConfirmEngine.Animation, configuration: HoldToConfirmConfiguration) -> Animation? {
        let animations = configuration.animations
        switch kind {
        case .none: return nil
        case _ where reduceMotion: return animations.reducedMotion
        case .spring: return animations.springBack
        case .snap: return animations.snap
        case .nudge: return animations.nudge
        case .smooth: return animations.transition
        }
    }

    private func celebrate(_ succeeded: Bool, style: HoldToConfirmCompletionStyle) {
        guard previewState == nil else { return }
        guard succeeded else {
            if style == .morph && !reduceMotion {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { celebration = 0 }
            } else {
                celebration = 0
            }
            return
        }
        celebration = 0
        guard !reduceMotion, style != .checkmark else {
            celebration = 1
            return
        }
        let animation: Animation
        switch style {
        case .bounce: animation = .easeOut(duration: 0.5)
        case .morph, .flip: animation = .spring(response: 0.55, dampingFraction: 0.78)
        case .ripple, .burst, .checkmark: animation = .easeOut(duration: 0.75)
        }
        withAnimation(animation) { celebration = 1 }
    }

    private func run(_ trigger: SlideToConfirmTrigger) {
        let action = self.action
        Task { @MainActor in
            let outcome: ConfirmEngine.Outcome
            do {
                try await action(trigger)
                outcome = .success
            } catch is CancellationError {
                outcome = .cancelled
            } catch let failure as SlideToConfirmFailure {
                outcome = .failure(message: failure.message)
            } catch {
                outcome = .failure(message: nil)
            }
            perform { $0.finish(outcome, at: $1) }
        }
    }

    private func runNextDeadline() async {
        guard previewState == nil, let deadline = engine.nextDeadline else { return }
        let delay = deadline - Date().timeIntervalSinceReferenceDate
        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        guard !Task.isCancelled else { return }
        perform { engine, now in engine.tick(at: max(now, deadline)) }
    }

    private func reportProgressWhileTimeDependent() async {
        guard previewState == nil else { return }
        while !Task.isCancelled, engine.isTimeDependent {
            let now = Date().timeIntervalSinceReferenceDate
            reporter.report(engine.snapshot(at: now).publicState(isEnabled: isEnabled), to: stateHandler)
            try? await Task.sleep(nanoseconds: 16_000_000)
        }
    }

    private func activateFromAccessibility() {
        guard isEnabled, previewState == nil, engine.phase != .processing, engine.phase != .success else { return }
        if accessibilityAlert != nil {
            isShowingAccessibilityAlert = true
        } else {
            perform { $0.activate(.accessibility, at: $1) }
        }
    }
}
#endif
