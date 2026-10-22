#if canImport(SwiftUI)
import SwiftUI

/// A control that confirms a consequential action when the person slides the knob to the end,
/// or simply presses and holds anywhere on it.
///
/// ```swift
/// SlideToConfirm("Slide or hold to send") {
///     try await transfer.send()
/// }
/// ```
///
/// Both paths commit at the same point, play the same haptics and land in the same states:
/// **processing** while your action runs, then **success** or, if it throws, **failure**.
///
/// - **Drag**: drag the knob past ``SlideToConfirmConfiguration/commitThreshold`` and release.
/// - **Hold**: keep a finger still for ``SlideToConfirmConfiguration/holdDelay``, then hold for
///   ``SlideToConfirmConfiguration/holdDuration``. Lift early and it springs back.
/// - **Take over**: while holding, move the finger on the knob to drag it from where it is.
/// - **Keyboard**: Return or Space (iOS 17 and macOS 14 or later).
/// - **Assistive technologies**: the control is a button named after its idle label.
///
/// Customize everything with ``SlideToConfirmConfiguration`` and the `slideToConfirm…` modifiers.
public struct SlideToConfirm: View {
    private let labels: SlideToConfirmLabels
    private let action: @MainActor (SlideToConfirmTrigger) async throws -> Void

    @Environment(\.slideToConfirmConfiguration) private var configuration
    @Environment(\.slideToConfirmHaptics) private var haptics
    @Environment(\.slideToConfirmPreviewState) private var previewState
    @Environment(\.slideToConfirmStateHandler) private var stateHandler
    @Environment(\.slideToConfirmKnobBuilder) private var knobBuilder
    @Environment(\.slideToConfirmAccessibilityAlert) private var accessibilityAlert
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var engine = ConfirmEngine()
    @State private var labelLength: CGFloat = 0
    @State private var shakes = 0
    @State private var isGestureActive = false
    @State private var isShowingAccessibilityAlert = false
    @State private var reporter = StateReporter()
    @GestureState private var isTouching = false

    // MARK: Initializers

    /// Creates a control with labels for every state and an action that learns how it was confirmed.
    ///
    /// - Parameters:
    ///   - labels: The text for each state.
    ///   - action: Runs on confirm. The control shows processing until it returns, then success.
    ///     Throw to show failure; throw ``SlideToConfirmFailure`` to choose the failure text,
    ///     or `CancellationError` to return to idle quietly.
    public init(
        labels: SlideToConfirmLabels,
        action: @escaping @MainActor (SlideToConfirmTrigger) async throws -> Void
    ) {
        self.labels = labels
        self.action = action
    }

    /// Creates a control with labels for every state.
    public init(
        labels: SlideToConfirmLabels,
        action: @escaping @MainActor () async throws -> Void
    ) {
        self.init(labels: labels, action: { @MainActor _ in try await action() })
    }

    /// Creates a control with a localized idle label and built-in labels for the other states.
    public init(
        _ titleKey: LocalizedStringKey,
        action: @escaping @MainActor () async throws -> Void
    ) {
        self.init(labels: SlideToConfirmLabels(titleKey), action: action)
    }

    /// Creates a control with a localized idle label, and an action that learns how it was confirmed.
    public init(
        _ titleKey: LocalizedStringKey,
        action: @escaping @MainActor (SlideToConfirmTrigger) async throws -> Void
    ) {
        self.init(labels: SlideToConfirmLabels(titleKey), action: action)
    }

    /// Creates a control with a verbatim idle label.
    @_disfavoredOverload
    public init<S: StringProtocol>(
        _ title: S,
        action: @escaping @MainActor () async throws -> Void
    ) {
        self.init(labels: SlideToConfirmLabels(idle: Text(title)), action: action)
    }

    /// Creates a control with a verbatim idle label, and an action that learns how it was confirmed.
    @_disfavoredOverload
    public init<S: StringProtocol>(
        _ title: S,
        action: @escaping @MainActor (SlideToConfirmTrigger) async throws -> Void
    ) {
        self.init(labels: SlideToConfirmLabels(idle: Text(title)), action: action)
    }

    // MARK: Body

    public var body: some View {
        let configuration = self.configuration
        let isVertical = configuration.direction.isVertical
        let thickness = resolvedThickness
        let maxLength = configuration.maxLength ?? .infinity

        GeometryReader { proxy in
            trackContainer(size: proxy.size, thickness: thickness)
        }
        .environment(\.layoutDirection, .leftToRight)
        .frame(width: isVertical ? thickness : nil, height: isVertical ? nil : thickness)
        .frame(
            minWidth: isVertical ? nil : thickness * 2,
            idealWidth: isVertical ? nil : configuration.idealLength,
            maxWidth: isVertical ? nil : maxLength,
            minHeight: isVertical ? thickness * 2 : nil,
            idealHeight: isVertical ? configuration.idealLength : nil,
            maxHeight: isVertical ? maxLength : nil
        )
        .modifier(ShakeEffect(animatableData: CGFloat(shakes)))
        .onPreferenceChange(LabelLengthKey.self) { labelLength = $0 }
        .stcOnChange(of: isTouching) { touching in
            // The system cancelled the gesture without ending it.
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

    private func trackContainer(size: CGSize, thickness: CGFloat) -> some View {
        let direction = configuration.direction
        let length = direction.isVertical ? size.height : size.width
        let layout = TrackLayout(
            length: Double(length),
            thickness: Double(thickness),
            knobInset: Double(configuration.knobInset),
            labelEdgePadding: Double(configuration.labelEdgePadding),
            labelKnobSpacing: Double(configuration.labelKnobSpacing)
        )
        let displayed = displayedEngine
        let isPreview = previewState != nil

        return TimelineView(.animation(minimumInterval: nil, paused: !displayed.isTimeDependent)) { context in
            let snapshot = resolvedSnapshot(displayed, at: context.date)
            SlideTrack(
                snapshot: snapshot,
                layout: layout,
                configuration: configuration,
                palette: configuration.theme.palette(for: colorScheme),
                label: labels.text(for: snapshot.label, failureMessage: snapshot.failureMessage),
                font: labelFont,
                labelLength: labelLength,
                textDirection: layoutDirection,
                isMirrored: isMirrored,
                rotation: rotation,
                isAnimated: !isPreview && !reduceMotion,
                knobBuilder: knobBuilder,
                direction: direction
            )
            .frame(width: length, height: thickness)
            .rotationEffect(rotation)
            .frame(width: size.width, height: size.height)
        }
        .contentShape(TrackShape(cornerRadius: configuration.cornerRadius))
        .gesture(dragGesture(layout: layout), including: isPreview ? .none : .all)
    }

    // MARK: Derived values

    private var displayedEngine: ConfirmEngine {
        guard let previewState else { return engine }
        return ConfirmEngine.preview(previewState, settings: configuration.engineSettings)
    }

    private func resolvedSnapshot(_ engine: ConfirmEngine, at date: Date) -> ConfirmSnapshot {
        var snapshot = engine.snapshot(at: date.timeIntervalSinceReferenceDate)
        if !isEnabled { snapshot.isEnabled = false }
        return snapshot
    }

    private var isMirrored: Bool {
        configuration.direction == .trailing && layoutDirection == .rightToLeft
    }

    private var rotation: Angle {
        switch configuration.direction {
        case .trailing: return .zero
        case .down: return .degrees(90)
        case .up: return .degrees(-90)
        }
    }

    private var typeScale: CGFloat {
        guard configuration.labelFont == nil else { return 1 }
        return min(dynamicTypeSize, configuration.maximumDynamicTypeSize).stcBodyScale
    }

    private var labelFont: Font {
        configuration.labelFont ?? .system(
            size: configuration.labelSize * typeScale,
            weight: configuration.labelWeight,
            design: configuration.labelDesign
        )
    }

    /// The configured thickness, grown to fit the label at accessibility text sizes.
    private var resolvedThickness: CGFloat {
        let base = max(configuration.thickness, configuration.knobInset * 2 + 8)
        guard configuration.growsWithDynamicType else { return base }
        return max(base, (configuration.labelSize * typeScale * 2.6).rounded(.up))
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

    private func dragGesture(layout: TrackLayout) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .updating($isTouching) { _, isTouching, _ in isTouching = true }
            .onChanged { value in
                if !isGestureActive {
                    isGestureActive = true
                    let onKnob = isOnKnob(value.startLocation, layout: layout)
                    haptics.prepare?()
                    perform { $0.touchDown(onKnob: onKnob, travel: layout.travel, at: $1) }
                }
                let movement = movement(for: value.translation)
                perform { $0.touchMoved(along: movement.along, distance: movement.distance, at: $1) }
            }
            .onEnded { _ in
                guard isGestureActive else { return }
                isGestureActive = false
                perform { $0.touchUp(at: $1) }
            }
    }

    /// Whether `point`, in the unrotated container's coordinates, lands on the knob.
    private func isOnKnob(_ point: CGPoint, layout: TrackLayout) -> Bool {
        let progress = engine.snapshot(at: Date().timeIntervalSinceReferenceDate).progress
        let start = layout.knobLeading(progress: progress)
        let along: Double
        switch configuration.direction {
        case .trailing: along = Double(isMirrored ? CGFloat(layout.length) - point.x : point.x)
        case .down: along = Double(point.y)
        case .up: along = layout.length - Double(point.y)
        }
        let slop = 8.0
        return along >= start - slop && along <= start + layout.knobDiameter + slop
    }

    /// Translation along the slide direction, positive toward the end, and in total.
    private func movement(for translation: CGSize) -> (along: Double, distance: Double) {
        let along: CGFloat
        switch configuration.direction {
        case .trailing: along = isMirrored ? -translation.width : translation.width
        case .down: along = translation.height
        case .up: along = -translation.height
        }
        return (Double(along), Double(hypot(translation.width, translation.height)))
    }

    // MARK: Engine

    /// Applies a change to the engine with the animation it asks for, then performs its effects.
    private func perform(_ change: (inout ConfirmEngine, TimeInterval) -> ConfirmEngine.Update) {
        guard previewState == nil else { return }
        let now = Date().timeIntervalSinceReferenceDate
        var next = engine
        next.updateSettings(configuration.engineSettings)
        let wasFailure = next.phase == .failure
        let update = change(&next, now)

        if let animation = animation(for: update.animation) {
            withAnimation(animation) { engine = next }
        } else {
            engine = next
        }
        // Report from the engine itself, never from a rendered frame, so observers always see the
        // state the control is actually in.
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

    private func animation(for kind: ConfirmEngine.Animation) -> Animation? {
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

    /// Reports hold and drain progress to the observer while it changes without input. Reads the
    /// live engine on every tick and stops as soon as the hold or drain ends.
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

/// Delivers each state change to the observer once.
final class StateReporter {
    private var lastReported: SlideToConfirmState?

    func report(_ state: SlideToConfirmState, to handler: ((SlideToConfirmState) -> Void)?) {
        guard state != lastReported else { return }
        lastReported = state
        handler?(state)
    }
}

/// Return or Space confirms while the control has keyboard focus.
struct KeyboardActivation: ViewModifier {
    let isEnabled: Bool
    let activate: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 17, macOS 14, *) {
            content
                .focusable(isEnabled)
                .onKeyPress(keys: [.return, .space]) { _ in
                    activate()
                    return .handled
                }
        } else {
            content
        }
    }
}

extension DynamicTypeSize {
    /// The body text size at this setting relative to the default, from Apple's type ramp.
    var stcBodyScale: CGFloat {
        switch self {
        case .xSmall: return 14 / 17
        case .small: return 15 / 17
        case .medium: return 16 / 17
        case .large: return 1
        case .xLarge: return 19 / 17
        case .xxLarge: return 21 / 17
        case .xxxLarge: return 23 / 17
        case .accessibility1: return 28 / 17
        case .accessibility2: return 33 / 17
        case .accessibility3: return 40 / 17
        case .accessibility4: return 47 / 17
        case .accessibility5: return 53 / 17
        @unknown default: return 1
        }
    }
}
#endif
