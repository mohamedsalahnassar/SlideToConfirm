import Foundation

/// The interaction model behind `SlideToConfirm`.
///
/// A pure value type: it never reads the clock and never touches UI frameworks, so every path
/// can be exercised deterministically in tests. The view
///
/// 1. feeds it touch events stamped with the current time,
/// 2. renders `snapshot(at:)` once per frame while `isTimeDependent` is `true`, and
/// 3. calls `tick(at:)` whenever `nextDeadline` passes.
///
/// Every mutating call returns an ``Update`` describing how to animate the change and which
/// side effects (haptics, running the action) to perform.
struct ConfirmEngine: Equatable {

    // MARK: Types

    struct Settings: Equatable {
        var holdBehavior: SlideToConfirmHoldBehavior = .combined
        var allowsDragging = true
        var holdDuration: TimeInterval = 1.2
        var holdDelay: TimeInterval = 0.18
        var commitThreshold: Double = 0.9
        var dragActivationDistance: Double = 6
        var holdCancellationDistance: Double = 12
        var fillDrainSpeed: Double = 3
        var nudgesOnTap = true
        var nudgeProgress: Double = 0.07
        var nudgeDuration: TimeInterval = 0.17
        var holdHapticMarks = 3
        var activationDelay: TimeInterval = 0.36
        var failureDisplayDuration: TimeInterval = 2
        var successResetDelay: TimeInterval?

        /// Clamps every value into a range the engine can work with.
        var sanitized: Settings {
            var s = self
            s.holdDuration = max(0.05, holdDuration)
            s.holdDelay = max(0, holdDelay)
            s.commitThreshold = min(max(commitThreshold, 0.05), 1)
            s.dragActivationDistance = max(0, dragActivationDistance)
            s.holdCancellationDistance = max(0, holdCancellationDistance)
            s.fillDrainSpeed = max(0.1, fillDrainSpeed)
            s.nudgeProgress = min(max(nudgeProgress, 0), 0.5)
            s.nudgeDuration = max(0, nudgeDuration)
            s.holdHapticMarks = max(0, holdHapticMarks)
            s.activationDelay = max(0, activationDelay)
            s.failureDisplayDuration = max(0, failureDisplayDuration)
            s.successResetDelay = successResetDelay.map { max(0, $0) }
            return s
        }
    }

    /// Internal interaction, a superset of the public one.
    enum Interaction: Equatable {
        case none, pending, dragging, holding, nudging

        var publicValue: SlideToConfirmInteraction {
            switch self {
            case .none, .nudging: return .none
            case .pending: return .pending
            case .dragging: return .dragging
            case .holding: return .holding
            }
        }
    }

    /// How the view should animate the change an update describes.
    enum Animation: Int, Equatable, Comparable {
        /// Apply immediately. Used while a finger drives the control.
        case none
        /// Cross-fade colors and labels.
        case smooth
        /// A small hop, for the tap hint.
        case nudge
        /// Spring back to the start.
        case spring
        /// Snap to the end on commit.
        case snap

        static func < (lhs: Animation, rhs: Animation) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    enum Effect: Equatable {
        case haptic(SlideToConfirmHapticEvent)
        case confirm(SlideToConfirmTrigger)
    }

    struct Update: Equatable {
        var animation: Animation = .none
        var effects: [Effect] = []

        mutating func merge(_ other: Update) {
            animation = max(animation, other.animation)
            effects += other.effects
        }

        var hapticEvents: [SlideToConfirmHapticEvent] {
            effects.compactMap { if case let .haptic(event) = $0 { return event } else { return nil } }
        }

        var confirmedTrigger: SlideToConfirmTrigger? {
            for effect in effects { if case let .confirm(trigger) = effect { return trigger } }
            return nil
        }
    }

    /// The outcome of the action, reported back with `finish(_:at:)`.
    enum Outcome: Equatable {
        case success
        case failure(message: String?)
        case cancelled
    }

    private struct Touch: Equatable {
        var onKnob: Bool
        var travel: Double
        var startProgress: Double
        var alongOffset: Double = 0
        var tookOverHold = false
    }

    /// A value moving linearly over time from `from`, starting at `start`.
    private struct Ramp: Equatable {
        var start: TimeInterval
        var from: Double
    }

    // MARK: State

    private(set) var settings: Settings
    private(set) var isEnabled = true
    private(set) var phase: SlideToConfirmPhase = .idle
    private(set) var interaction: Interaction = .none
    /// Knob position, 0...1.
    private(set) var progress: Double = 0
    /// Solid fill for ``SlideToConfirmHoldBehavior/fill``, 0...1.
    private(set) var fillProgress: Double = 0
    /// Countdown ring on the knob, 0...1.
    private(set) var ringProgress: Double = 0
    private(set) var isArmed = false
    private(set) var failureMessage: String?
    private(set) var lastTrigger: SlideToConfirmTrigger?

    private var touch: Touch?
    private var pendingSince: TimeInterval?
    private var hold: Ramp?
    private var drain: Ramp?
    private var holdMarksFired = 0
    private var nudgeEndsAt: TimeInterval?
    private var activation: (at: TimeInterval, trigger: SlideToConfirmTrigger)?
    private var resetAt: TimeInterval?

    init(settings: Settings = Settings()) {
        self.settings = settings.sanitized
    }

    static func == (lhs: ConfirmEngine, rhs: ConfirmEngine) -> Bool {
        lhs.settings == rhs.settings && lhs.isEnabled == rhs.isEnabled && lhs.phase == rhs.phase
            && lhs.interaction == rhs.interaction && lhs.progress == rhs.progress
            && lhs.fillProgress == rhs.fillProgress && lhs.ringProgress == rhs.ringProgress
            && lhs.isArmed == rhs.isArmed && lhs.failureMessage == rhs.failureMessage
            && lhs.lastTrigger == rhs.lastTrigger && lhs.touch == rhs.touch
            && lhs.pendingSince == rhs.pendingSince && lhs.hold == rhs.hold && lhs.drain == rhs.drain
            && lhs.holdMarksFired == rhs.holdMarksFired && lhs.nudgeEndsAt == rhs.nudgeEndsAt
            && lhs.activation?.at == rhs.activation?.at && lhs.activation?.trigger == rhs.activation?.trigger
            && lhs.resetAt == rhs.resetAt
    }

    // MARK: Queries

    /// `true` while a finger is down on the control.
    var isTracking: Bool { touch != nil }

    /// `true` while progress changes every frame without input, so the view must redraw continuously.
    var isTimeDependent: Bool { hold != nil || drain != nil }

    /// The next moment `tick(at:)` has work to do, or `nil` when nothing is scheduled.
    var nextDeadline: TimeInterval? {
        var candidates: [TimeInterval] = []
        if interaction == .pending, let since = pendingSince {
            candidates.append(since + settings.holdDelay)
        }
        if let hold {
            candidates.append(hold.start + max(0, 1 - hold.from) * settings.holdDuration)
            if let mark = nextHoldMark {
                candidates.append(hold.start + max(0, mark - hold.from) * settings.holdDuration)
            }
        }
        if let drain {
            candidates.append(drain.start + drain.from * drainDuration)
        }
        if let nudgeEndsAt { candidates.append(nudgeEndsAt) }
        if let activation { candidates.append(activation.at) }
        if let resetAt { candidates.append(resetAt) }
        return candidates.min()
    }

    // MARK: Touch input

    /// A finger went down on the control.
    ///
    /// - Parameters:
    ///   - onKnob: Whether the finger landed on the knob. Only the knob can be dragged.
    ///   - travel: The distance, in points, the knob travels from start to end.
    mutating func touchDown(onKnob: Bool, travel: Double, at now: TimeInterval) -> Update {
        guard isEnabled, touch == nil else { return Update() }
        var update = Update()
        if phase == .failure {
            // Let the person retry straight away instead of waiting out the failure label.
            resetToIdle()
            update.animation = .smooth
        }
        guard phase == .idle, activation == nil else { return update }

        if interaction == .nudging {
            nudgeEndsAt = nil
            interaction = .none
        }
        if let drain {
            fillProgress = value(of: drain, decreasingAt: now)
            self.drain = nil
        }

        let grabsKnob = onKnob && settings.allowsDragging
        if !grabsKnob && settings.holdBehavior == .none {
            if settings.nudgesOnTap { update.merge(nudge(at: now)) }
            return update
        }

        touch = Touch(onKnob: grabsKnob, travel: max(1, travel), startProgress: progress)
        if settings.holdBehavior == .none {
            interaction = .dragging
        } else {
            interaction = .pending
            pendingSince = now
        }
        return update
    }

    /// The finger moved.
    ///
    /// - Parameters:
    ///   - along: Translation since touch-down along the slide direction, positive toward the end.
    ///   - distance: Total translation since touch-down in any direction.
    mutating func touchMoved(along: Double, distance: Double, at now: TimeInterval) -> Update {
        guard var touch else { return Update() }
        switch interaction {
        case .pending:
            if touch.onKnob && abs(along) > settings.dragActivationDistance {
                pendingSince = nil
                interaction = .dragging
                return drag(along: along)
            }
            if !touch.onKnob && distance > settings.holdCancellationDistance {
                // Probably a scroll or a stray touch: let it go without a hint.
                pendingSince = nil
                self.touch = nil
                interaction = .none
            }
            return Update()

        case .holding:
            guard distance > settings.holdCancellationDistance else { return Update() }
            freezeHold(at: now)
            guard touch.onKnob else {
                self.touch = nil
                return release(at: now)
            }
            // Take over: the knob continues from wherever the hold left it.
            touch.startProgress = progress
            touch.alongOffset = along
            touch.tookOverHold = true
            self.touch = touch
            ringProgress = 0
            if settings.holdBehavior == .fill, fillProgress > 0 {
                drain = Ramp(start: now, from: fillProgress)
            }
            interaction = .dragging
            return Update()

        case .dragging:
            return drag(along: along)

        case .none, .nudging:
            return Update()
        }
    }

    /// The finger lifted.
    mutating func touchUp(at now: TimeInterval) -> Update {
        pendingSince = nil
        guard let touch else { return Update() }
        self.touch = nil
        switch interaction {
        case .pending:
            interaction = .none
            return settings.nudgesOnTap ? nudge(at: now) : Update()
        case .dragging:
            if progress >= settings.commitThreshold {
                return commit(touch.tookOverHold ? .holdThenDrag : .drag, at: now)
            }
            return springBack()
        case .holding:
            freezeHold(at: now)
            return release(at: now)
        case .none, .nudging:
            return Update()
        }
    }

    /// The system cancelled the touch, for example because a sheet appeared. Never confirms.
    mutating func touchCancelled(at now: TimeInterval) -> Update {
        pendingSince = nil
        guard touch != nil else { return Update() }
        touch = nil
        switch interaction {
        case .pending:
            interaction = .none
            return Update()
        case .dragging:
            return springBack()
        case .holding:
            freezeHold(at: now)
            return release(at: now)
        case .none, .nudging:
            return Update()
        }
    }

    // MARK: Other input

    /// Confirms without a gesture: the knob snaps to the end, then the action runs after
    /// `activationDelay`. Used for the keyboard and assistive technologies.
    mutating func activate(_ trigger: SlideToConfirmTrigger, at now: TimeInterval) -> Update {
        guard isEnabled, touch == nil, activation == nil else { return Update() }
        var update = Update()
        if phase == .failure {
            resetToIdle()
        }
        guard phase == .idle else { return update }
        nudgeEndsAt = nil
        hold = nil
        drain = nil
        interaction = .none
        isArmed = false
        ringProgress = 0
        progress = 1
        if settings.activationDelay == 0 {
            update.merge(commit(trigger, at: now))
            return update
        }
        activation = (now + settings.activationDelay, trigger)
        update.animation = .snap
        return update
    }

    /// Reports how the action ended.
    mutating func finish(_ outcome: Outcome, at now: TimeInterval) -> Update {
        guard phase == .processing else { return Update() }
        switch outcome {
        case .success:
            phase = .success
            fillProgress = 0
            resetAt = settings.successResetDelay.map { now + $0 }
            return Update(animation: .smooth, effects: [.haptic(.success)])
        case let .failure(message):
            phase = .failure
            failureMessage = message
            progress = 0
            fillProgress = 0
            resetAt = now + settings.failureDisplayDuration
            return Update(animation: .spring, effects: [.haptic(.failure)])
        case .cancelled:
            resetToIdle()
            return Update(animation: .spring)
        }
    }

    /// Returns to idle from any phase, abandoning any touch in progress.
    mutating func reset(at now: TimeInterval) -> Update {
        resetToIdle()
        return Update(animation: .spring)
    }

    /// Enables or disables the control. Disabling abandons any touch without confirming.
    mutating func setEnabled(_ enabled: Bool, at now: TimeInterval) -> Update {
        guard enabled != isEnabled else { return Update() }
        var update = Update()
        if !enabled {
            update.merge(touchCancelled(at: now))
            if activation != nil {
                activation = nil
                progress = 0
                update.animation = max(update.animation, .spring)
            }
            if interaction == .nudging {
                nudgeEndsAt = nil
                interaction = .none
                progress = 0
            }
        }
        isEnabled = enabled
        update.animation = max(update.animation, .smooth)
        return update
    }

    /// Replaces the settings. Takes effect from the next gesture.
    mutating func updateSettings(_ newSettings: Settings) {
        settings = newSettings.sanitized
    }

    // MARK: Time

    /// Runs everything that is due at `now`: starting a hold, completing it, haptic marks,
    /// draining, ending a nudge, delayed activation and resetting after success or failure.
    mutating func tick(at now: TimeInterval) -> Update {
        var update = Update()

        if interaction == .pending, let since = pendingSince, now >= since + settings.holdDelay {
            update.merge(beginHold(at: since + settings.holdDelay))
        }

        if let hold {
            let value = value(of: hold, increasingAt: now)
            while let mark = nextHoldMark, value >= mark {
                holdMarksFired += 1
                update.effects.append(.haptic(.holdProgress(mark)))
            }
            if value >= 1 {
                if settings.holdBehavior == .fill { fillProgress = 1 }
                update.merge(commit(.hold, at: now))
            }
        }

        if let drain, value(of: drain, decreasingAt: now) <= 0 {
            fillProgress = 0
            self.drain = nil
        }

        if let end = nudgeEndsAt, now >= end {
            nudgeEndsAt = nil
            if interaction == .nudging { interaction = .none }
            progress = 0
            update.animation = max(update.animation, .spring)
        }

        if let activation, now >= activation.at {
            self.activation = nil
            update.merge(commit(activation.trigger, at: now))
        }

        if let resetAt, now >= resetAt {
            resetToIdle()
            update.animation = max(update.animation, .smooth)
        }

        return update
    }

    /// The values to render at `now`, with time-driven progress resolved.
    func snapshot(at now: TimeInterval) -> ConfirmSnapshot {
        var knob = progress
        var fill = fillProgress
        var ring = ringProgress
        if let hold {
            let value = value(of: hold, increasingAt: now)
            if settings.holdBehavior == .fill { fill = value } else { knob = value }
            ring = value
        }
        if let drain {
            fill = value(of: drain, decreasingAt: now)
        }
        return ConfirmSnapshot(
            phase: phase,
            interaction: interaction,
            holdBehavior: settings.holdBehavior,
            progress: knob,
            fillProgress: fill,
            ringProgress: ring,
            isArmed: isArmed,
            isEnabled: isEnabled,
            failureMessage: failureMessage
        )
    }

    // MARK: Previews

    /// An engine frozen in `state`, for previews and snapshots.
    static func preview(_ state: SlideToConfirmPreviewState, settings: Settings) -> ConfirmEngine {
        var engine = ConfirmEngine(settings: settings)
        let clamp = { (value: Double) in min(max(value, 0), 1) }
        switch state {
        case .idle:
            break
        case let .dragging(progress):
            engine.interaction = .dragging
            engine.progress = clamp(progress)
            engine.isArmed = engine.progress >= engine.settings.commitThreshold
        case let .armed(progress):
            engine.interaction = .dragging
            engine.progress = clamp(progress)
            engine.isArmed = true
        case let .holding(progress):
            engine.interaction = .holding
            if engine.settings.holdBehavior == .fill {
                engine.fillProgress = clamp(progress)
            } else {
                engine.progress = clamp(progress)
            }
            engine.ringProgress = clamp(progress)
        case .processing:
            engine.phase = .processing
            engine.progress = 1
        case .success:
            engine.phase = .success
            engine.progress = 1
        case let .failure(message):
            engine.phase = .failure
            engine.failureMessage = message
        case .disabled:
            engine.isEnabled = false
        }
        return engine
    }

    // MARK: Private

    private var drainDuration: TimeInterval { settings.holdDuration / settings.fillDrainSpeed }

    private var nextHoldMark: Double? {
        guard holdMarksFired < settings.holdHapticMarks else { return nil }
        return Double(holdMarksFired + 1) / Double(settings.holdHapticMarks + 1)
    }

    private func value(of ramp: Ramp, increasingAt now: TimeInterval) -> Double {
        min(1, ramp.from + max(0, now - ramp.start) / settings.holdDuration)
    }

    private func value(of ramp: Ramp, decreasingAt now: TimeInterval) -> Double {
        max(0, ramp.from - max(0, now - ramp.start) / drainDuration)
    }

    private mutating func drag(along: Double) -> Update {
        guard let touch else { return Update() }
        progress = min(max(touch.startProgress + (along - touch.alongOffset) / touch.travel, 0), 1)
        let armed = progress >= settings.commitThreshold
        defer { isArmed = armed }
        return armed && !isArmed ? Update(effects: [.haptic(.armed)]) : Update()
    }

    private mutating func beginHold(at time: TimeInterval) -> Update {
        pendingSince = nil
        interaction = .holding
        let from = settings.holdBehavior == .fill ? fillProgress : progress
        hold = Ramp(start: time, from: from)
        holdMarksFired = 0
        while let mark = nextHoldMark, mark <= from { holdMarksFired += 1 }
        return Update(effects: [.haptic(.holdBegan)])
    }

    /// Stores the hold's current value and stops the clock.
    private mutating func freezeHold(at now: TimeInterval) {
        guard let hold else { return }
        let value = value(of: hold, increasingAt: now)
        if settings.holdBehavior == .fill { fillProgress = value } else { progress = value }
        ringProgress = value
        self.hold = nil
    }

    private mutating func release(at now: TimeInterval) -> Update {
        hold = nil
        ringProgress = 0
        isArmed = false
        interaction = .none
        guard phase == .idle else { return Update() }
        if settings.holdBehavior == .fill {
            if fillProgress > 0 { drain = Ramp(start: now, from: fillProgress) }
        } else {
            progress = 0
        }
        return Update(animation: .spring)
    }

    private mutating func springBack() -> Update {
        progress = 0
        isArmed = false
        interaction = .none
        return Update(animation: .spring)
    }

    private mutating func nudge(at now: TimeInterval) -> Update {
        guard phase == .idle, settings.nudgeProgress > 0 else { return Update() }
        interaction = .nudging
        progress = settings.nudgeProgress
        nudgeEndsAt = now + settings.nudgeDuration
        return Update(animation: .nudge)
    }

    private mutating func commit(_ trigger: SlideToConfirmTrigger, at now: TimeInterval) -> Update {
        touch = nil
        pendingSince = nil
        hold = nil
        drain = nil
        nudgeEndsAt = nil
        activation = nil
        resetAt = nil
        progress = 1
        ringProgress = 0
        isArmed = false
        interaction = .none
        failureMessage = nil
        phase = .processing
        lastTrigger = trigger
        return Update(animation: .snap, effects: [.haptic(.confirmed), .confirm(trigger)])
    }

    private mutating func resetToIdle() {
        touch = nil
        pendingSince = nil
        hold = nil
        drain = nil
        nudgeEndsAt = nil
        activation = nil
        resetAt = nil
        holdMarksFired = 0
        phase = .idle
        interaction = .none
        progress = 0
        fillProgress = 0
        ringProgress = 0
        isArmed = false
        failureMessage = nil
    }
}
