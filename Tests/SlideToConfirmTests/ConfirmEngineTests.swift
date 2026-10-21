import XCTest
@testable import SlideToConfirm

final class ConfirmEngineTests: XCTestCase {

    private let travel = 300.0

    private func makeEngine(_ configure: (inout ConfirmEngine.Settings) -> Void = { _ in }) -> ConfirmEngine {
        var settings = ConfirmEngine.Settings()
        configure(&settings)
        return ConfirmEngine(settings: settings)
    }

    /// Runs every deadline up to and including `time`, the way the view's timer does.
    @discardableResult
    private func advance(_ engine: inout ConfirmEngine, to time: TimeInterval) -> ConfirmEngine.Update {
        var update = ConfirmEngine.Update()
        var guardCount = 0
        while let deadline = engine.nextDeadline, deadline <= time, guardCount < 100 {
            update.merge(engine.tick(at: deadline))
            guardCount += 1
        }
        update.merge(engine.tick(at: time))
        return update
    }

    // MARK: Drag

    func testDragPastThresholdConfirmsOnRelease() {
        var engine = makeEngine()
        _ = engine.touchDown(onKnob: true, travel: travel, at: 0)
        XCTAssertEqual(engine.interaction, .pending)

        _ = engine.touchMoved(along: 10, distance: 10, at: 0.05)
        XCTAssertEqual(engine.interaction, .dragging)
        XCTAssertEqual(engine.progress, 10 / travel, accuracy: 0.0001)

        let armed = engine.touchMoved(along: 280, distance: 280, at: 0.2)
        XCTAssertTrue(engine.isArmed)
        XCTAssertEqual(armed.hapticEvents, [.armed])

        let release = engine.touchUp(at: 0.3)
        XCTAssertEqual(release.confirmedTrigger, .drag)
        XCTAssertEqual(release.animation, .snap)
        XCTAssertEqual(engine.phase, .processing)
        XCTAssertEqual(engine.progress, 1)
        XCTAssertEqual(engine.lastTrigger, .drag)
        XCTAssertTrue(release.hapticEvents.contains(.confirmed))
    }

    func testArmedHapticFiresOncePerCrossing() {
        var engine = makeEngine()
        _ = engine.touchDown(onKnob: true, travel: travel, at: 0)
        XCTAssertEqual(engine.touchMoved(along: 280, distance: 280, at: 0.1).hapticEvents, [.armed])
        XCTAssertEqual(engine.touchMoved(along: 290, distance: 290, at: 0.15).hapticEvents, [])
        XCTAssertEqual(engine.touchMoved(along: 100, distance: 100, at: 0.2).hapticEvents, [])
        XCTAssertFalse(engine.isArmed)
        XCTAssertEqual(engine.touchMoved(along: 285, distance: 285, at: 0.25).hapticEvents, [.armed])
    }

    func testDragShortOfThresholdSpringsBack() {
        var engine = makeEngine()
        _ = engine.touchDown(onKnob: true, travel: travel, at: 0)
        _ = engine.touchMoved(along: 200, distance: 200, at: 0.1)
        let release = engine.touchUp(at: 0.2)
        XCTAssertNil(release.confirmedTrigger)
        XCTAssertEqual(release.animation, .spring)
        XCTAssertEqual(engine.progress, 0)
        XCTAssertEqual(engine.phase, .idle)
        XCTAssertEqual(engine.interaction, .none)
    }

    func testDragProgressIsClamped() {
        var engine = makeEngine()
        _ = engine.touchDown(onKnob: true, travel: travel, at: 0)
        _ = engine.touchMoved(along: -50, distance: 50, at: 0.05)
        XCTAssertEqual(engine.progress, 0)
        _ = engine.touchMoved(along: 900, distance: 900, at: 0.1)
        XCTAssertEqual(engine.progress, 1)
    }

    func testCustomThreshold() {
        var engine = makeEngine { $0.commitThreshold = 0.5 }
        _ = engine.touchDown(onKnob: true, travel: travel, at: 0)
        _ = engine.touchMoved(along: 160, distance: 160, at: 0.1)
        XCTAssertTrue(engine.isArmed)
        XCTAssertEqual(engine.touchUp(at: 0.2).confirmedTrigger, .drag)
    }

    func testDraggingDisabledTreatsKnobLikeTrack() {
        var engine = makeEngine { $0.allowsDragging = false }
        _ = engine.touchDown(onKnob: true, travel: travel, at: 0)
        _ = engine.touchMoved(along: 8, distance: 8, at: 0.05)
        XCTAssertEqual(engine.interaction, .pending, "a small move must not start a drag")
        _ = engine.touchMoved(along: 30, distance: 30, at: 0.1)
        XCTAssertEqual(engine.interaction, .none, "a large move off a hold-only control cancels")
    }

    // MARK: Hold

    func testHoldStartsAfterDelayAndConfirmsAtTheEnd() {
        var engine = makeEngine()
        _ = engine.touchDown(onKnob: false, travel: travel, at: 0)
        XCTAssertEqual(engine.nextDeadline ?? -1, 0.18, accuracy: 0.0001)

        let began = advance(&engine, to: 0.18)
        XCTAssertEqual(engine.interaction, .holding)
        XCTAssertEqual(began.hapticEvents, [.holdBegan])
        XCTAssertTrue(engine.isTimeDependent)

        let halfway = engine.snapshot(at: 0.18 + 0.6)
        XCTAssertEqual(halfway.progress, 0.5, accuracy: 0.0001)
        XCTAssertEqual(halfway.ringProgress, 0.5, accuracy: 0.0001)
        XCTAssertTrue(halfway.isFollowing)
        XCTAssertTrue(halfway.showsSolidFill)
        XCTAssertTrue(halfway.isKnobInverted)

        let done = advance(&engine, to: 0.18 + 1.2)
        XCTAssertEqual(done.confirmedTrigger, .hold)
        XCTAssertEqual(engine.phase, .processing)
        XCTAssertFalse(engine.isTimeDependent)
    }

    func testHoldFiresProgressMarks() {
        var engine = makeEngine { $0.holdHapticMarks = 3 }
        _ = engine.touchDown(onKnob: false, travel: travel, at: 0)
        let update = advance(&engine, to: 0.18 + 1.0)
        XCTAssertEqual(update.hapticEvents, [.holdBegan, .holdProgress(0.25), .holdProgress(0.5), .holdProgress(0.75)])
    }

    func testEarlyReleaseSpringsBackWithoutConfirming() {
        var engine = makeEngine()
        _ = engine.touchDown(onKnob: false, travel: travel, at: 0)
        advance(&engine, to: 0.5)
        let release = engine.touchUp(at: 0.5)
        XCTAssertNil(release.confirmedTrigger)
        XCTAssertEqual(release.animation, .spring)
        XCTAssertEqual(engine.progress, 0)
        XCTAssertEqual(engine.ringProgress, 0)
        XCTAssertEqual(engine.interaction, .none)
        XCTAssertNil(engine.nextDeadline)
    }

    func testQuickTapNudges() {
        var engine = makeEngine()
        _ = engine.touchDown(onKnob: false, travel: travel, at: 0)
        let tap = engine.touchUp(at: 0.05)
        XCTAssertEqual(tap.animation, .nudge)
        XCTAssertEqual(engine.progress, 0.07, accuracy: 0.0001)
        XCTAssertEqual(engine.snapshot(at: 0.05).interaction, .nudging)
        advance(&engine, to: 0.3)
        XCTAssertEqual(engine.progress, 0)
        XCTAssertEqual(engine.interaction, .none)
    }

    func testNudgeCanBeDisabled() {
        var engine = makeEngine { $0.nudgesOnTap = false }
        _ = engine.touchDown(onKnob: false, travel: travel, at: 0)
        XCTAssertEqual(engine.touchUp(at: 0.05).animation, .none)
        XCTAssertEqual(engine.progress, 0)
    }

    func testMovingOffKnobBeforeHoldCancelsQuietly() {
        var engine = makeEngine()
        _ = engine.touchDown(onKnob: false, travel: travel, at: 0)
        _ = engine.touchMoved(along: 0, distance: 20, at: 0.1)
        XCTAssertEqual(engine.interaction, .none)
        XCTAssertFalse(engine.isTracking)
        XCTAssertEqual(engine.touchUp(at: 0.2), ConfirmEngine.Update())
        advance(&engine, to: 2)
        XCTAssertEqual(engine.phase, .idle)
    }

    func testSmallMovesKeepTheHoldAlive() {
        var engine = makeEngine()
        _ = engine.touchDown(onKnob: false, travel: travel, at: 0)
        _ = engine.touchMoved(along: 3, distance: 5, at: 0.1)
        advance(&engine, to: 0.5)
        _ = engine.touchMoved(along: 4, distance: 9, at: 0.5)
        XCTAssertEqual(engine.interaction, .holding)
    }

    func testMovingOffTrackDuringHoldReleases() {
        var engine = makeEngine()
        _ = engine.touchDown(onKnob: false, travel: travel, at: 0)
        advance(&engine, to: 0.6)
        let update = engine.touchMoved(along: 0, distance: 40, at: 0.6)
        XCTAssertEqual(update.animation, .spring)
        XCTAssertEqual(engine.interaction, .none)
        XCTAssertEqual(engine.progress, 0)
    }

    func testTakingOverAHoldContinuesFromTheKnob() {
        var engine = makeEngine()
        _ = engine.touchDown(onKnob: true, travel: travel, at: 0)
        _ = engine.touchMoved(along: 2, distance: 2, at: 0.05)
        advance(&engine, to: 0.18 + 0.6)
        XCTAssertEqual(engine.interaction, .holding)

        _ = engine.touchMoved(along: 2, distance: 14, at: 0.78)
        XCTAssertEqual(engine.interaction, .dragging)
        XCTAssertEqual(engine.progress, 0.5, accuracy: 0.0001)
        XCTAssertEqual(engine.ringProgress, 0)

        _ = engine.touchMoved(along: 2 + 0.45 * travel, distance: 200, at: 0.9)
        XCTAssertEqual(engine.progress, 0.95, accuracy: 0.0001)
        XCTAssertEqual(engine.touchUp(at: 1).confirmedTrigger, .holdThenDrag)
    }

    func testHoldBehaviorNoneIsSlideOnly() {
        var engine = makeEngine { $0.holdBehavior = .none }
        _ = engine.touchDown(onKnob: false, travel: travel, at: 0)
        XCTAssertEqual(engine.interaction, .nudging, "a tap off the knob only hints")
        advance(&engine, to: 2)
        XCTAssertEqual(engine.phase, .idle)

        _ = engine.touchDown(onKnob: true, travel: travel, at: 3)
        XCTAssertEqual(engine.interaction, .dragging, "no hold delay when holding is off")
        _ = engine.touchMoved(along: 290, distance: 290, at: 3.1)
        XCTAssertEqual(engine.touchUp(at: 3.2).confirmedTrigger, .drag)
    }

    // MARK: Fill and glide

    func testFillHoldGrowsFillAndKeepsKnobStill() {
        var engine = makeEngine { $0.holdBehavior = .fill }
        _ = engine.touchDown(onKnob: false, travel: travel, at: 0)
        advance(&engine, to: 0.18)
        let snapshot = engine.snapshot(at: 0.18 + 0.3)
        XCTAssertEqual(snapshot.progress, 0)
        XCTAssertEqual(snapshot.fillProgress, 0.25, accuracy: 0.0001)
        XCTAssertTrue(snapshot.isFilling)
        XCTAssertFalse(snapshot.isFollowing)
        XCTAssertTrue(snapshot.isKnobInverted)
        XCTAssertEqual(snapshot.publicState.progress, 0.25, accuracy: 0.0001)
    }

    func testFillDrainsAtThreeTimesTheSpeedAfterEarlyRelease() {
        var engine = makeEngine { $0.holdBehavior = .fill }
        _ = engine.touchDown(onKnob: false, travel: travel, at: 0)
        advance(&engine, to: 0.18 + 0.6)
        _ = engine.touchUp(at: 0.78)
        XCTAssertEqual(engine.fillProgress, 0.5, accuracy: 0.0001)
        XCTAssertTrue(engine.isTimeDependent)
        // Drain takes holdDuration / 3 per unit: 0.5 drains in 0.2 s.
        XCTAssertEqual(engine.snapshot(at: 0.88).fillProgress, 0.25, accuracy: 0.0001)
        XCTAssertEqual(engine.nextDeadline ?? -1, 0.98, accuracy: 0.0001)
        advance(&engine, to: 1)
        XCTAssertEqual(engine.fillProgress, 0)
        XCTAssertFalse(engine.isTimeDependent)
    }

    func testTouchingDuringDrainResumesTheFill() {
        var engine = makeEngine { $0.holdBehavior = .fill }
        _ = engine.touchDown(onKnob: false, travel: travel, at: 0)
        advance(&engine, to: 0.78)
        _ = engine.touchUp(at: 0.78)
        _ = engine.touchDown(onKnob: false, travel: travel, at: 0.88)
        XCTAssertEqual(engine.fillProgress, 0.25, accuracy: 0.0001)
        advance(&engine, to: 0.88 + 0.18)
        XCTAssertEqual(engine.snapshot(at: 0.88 + 0.18 + 0.3).fillProgress, 0.5, accuracy: 0.0001)
    }

    func testFillHoldConfirms() {
        var engine = makeEngine { $0.holdBehavior = .fill }
        _ = engine.touchDown(onKnob: false, travel: travel, at: 0)
        let update = advance(&engine, to: 2)
        XCTAssertEqual(update.confirmedTrigger, .hold)
        XCTAssertEqual(engine.phase, .processing)
    }

    func testGlideMovesKnobWithoutSolidFill() {
        var engine = makeEngine { $0.holdBehavior = .glide }
        _ = engine.touchDown(onKnob: false, travel: travel, at: 0)
        advance(&engine, to: 0.18)
        let early = engine.snapshot(at: 0.18 + 0.24)
        XCTAssertEqual(early.progress, 0.2, accuracy: 0.0001)
        XCTAssertFalse(early.showsSolidFill)
        XCTAssertFalse(early.isKnobInverted)
        XCTAssertFalse(early.labelSitsBehindKnob)
        let late = engine.snapshot(at: 0.18 + 0.72)
        XCTAssertTrue(late.labelSitsBehindKnob)
    }

    // MARK: Outcomes

    func testSuccessRemainsByDefault() {
        var engine = makeEngine()
        _ = engine.activate(.accessibility, at: 0)
        advance(&engine, to: 1)
        XCTAssertEqual(engine.phase, .processing)
        let update = engine.finish(.success, at: 1)
        XCTAssertEqual(update.hapticEvents, [.success])
        XCTAssertEqual(engine.phase, .success)
        XCTAssertNil(engine.nextDeadline)
        _ = engine.touchDown(onKnob: true, travel: travel, at: 2)
        XCTAssertFalse(engine.isTracking, "a confirmed control ignores touches")
    }

    func testSuccessResetsAfterDelay() {
        var engine = makeEngine { $0.successResetDelay = 2 }
        _ = engine.activate(.keyboard, at: 0)
        advance(&engine, to: 1)
        _ = engine.finish(.success, at: 1)
        XCTAssertEqual(engine.nextDeadline, 3)
        advance(&engine, to: 3)
        XCTAssertEqual(engine.phase, .idle)
        XCTAssertEqual(engine.progress, 0)
    }

    func testFailureShowsMessageThenReturnsToIdle() {
        var engine = makeEngine { $0.failureDisplayDuration = 2 }
        _ = engine.activate(.accessibility, at: 0)
        advance(&engine, to: 1)
        let update = engine.finish(.failure(message: "Insufficient funds"), at: 1)
        XCTAssertEqual(update.hapticEvents, [.failure])
        XCTAssertEqual(engine.phase, .failure)
        XCTAssertEqual(engine.failureMessage, "Insufficient funds")
        XCTAssertEqual(engine.progress, 0)
        XCTAssertEqual(engine.snapshot(at: 1).label, .failure)
        advance(&engine, to: 3)
        XCTAssertEqual(engine.phase, .idle)
        XCTAssertNil(engine.failureMessage)
    }

    func testTouchDuringFailureRetriesImmediately() {
        var engine = makeEngine()
        _ = engine.activate(.accessibility, at: 0)
        advance(&engine, to: 1)
        _ = engine.finish(.failure(message: nil), at: 1)
        _ = engine.touchDown(onKnob: true, travel: travel, at: 1.2)
        XCTAssertEqual(engine.phase, .idle)
        XCTAssertTrue(engine.isTracking)
    }

    func testCancelledOutcomeReturnsToIdleQuietly() {
        var engine = makeEngine()
        _ = engine.activate(.accessibility, at: 0)
        advance(&engine, to: 1)
        let update = engine.finish(.cancelled, at: 1)
        XCTAssertEqual(update.hapticEvents, [])
        XCTAssertEqual(engine.phase, .idle)
    }

    func testFinishIsIgnoredOutsideProcessing() {
        var engine = makeEngine()
        XCTAssertEqual(engine.finish(.success, at: 0), ConfirmEngine.Update())
        XCTAssertEqual(engine.phase, .idle)
    }

    func testNoDoubleConfirmWhileProcessing() {
        var engine = makeEngine()
        _ = engine.touchDown(onKnob: true, travel: travel, at: 0)
        _ = engine.touchMoved(along: 290, distance: 290, at: 0.1)
        XCTAssertNotNil(engine.touchUp(at: 0.2).confirmedTrigger)
        _ = engine.touchDown(onKnob: true, travel: travel, at: 0.3)
        XCTAssertFalse(engine.isTracking)
        XCTAssertNil(engine.activate(.keyboard, at: 0.3).confirmedTrigger)
        XCTAssertNil(advance(&engine, to: 5).confirmedTrigger)
    }

    // MARK: Activation

    func testActivationSnapsThenConfirmsAfterDelay() {
        var engine = makeEngine()
        let update = engine.activate(.keyboard, at: 0)
        XCTAssertEqual(update.animation, .snap)
        XCTAssertNil(update.confirmedTrigger)
        XCTAssertEqual(engine.progress, 1)
        XCTAssertEqual(engine.nextDeadline ?? -1, 0.36, accuracy: 0.0001)
        let commit = advance(&engine, to: 0.36)
        XCTAssertEqual(commit.confirmedTrigger, .keyboard)
    }

    func testActivationWithoutDelayConfirmsImmediately() {
        var engine = makeEngine { $0.activationDelay = 0 }
        XCTAssertEqual(engine.activate(.accessibility, at: 0).confirmedTrigger, .accessibility)
    }

    // MARK: Enabled

    func testDisabledIgnoresInput() {
        var engine = makeEngine()
        _ = engine.setEnabled(false, at: 0)
        _ = engine.touchDown(onKnob: true, travel: travel, at: 0)
        XCTAssertFalse(engine.isTracking)
        XCTAssertNil(engine.activate(.accessibility, at: 0).confirmedTrigger)
        XCTAssertFalse(engine.snapshot(at: 0).isShimmering)
        XCTAssertFalse(engine.snapshot(at: 0).publicState.isEnabled)
    }

    func testDisablingMidHoldReleasesWithoutConfirming() {
        var engine = makeEngine()
        _ = engine.touchDown(onKnob: false, travel: travel, at: 0)
        advance(&engine, to: 0.6)
        _ = engine.setEnabled(false, at: 0.6)
        XCTAssertEqual(engine.interaction, .none)
        XCTAssertEqual(engine.progress, 0)
        XCTAssertNil(advance(&engine, to: 5).confirmedTrigger)
    }

    func testCancelledTouchNeverConfirms() {
        var engine = makeEngine()
        _ = engine.touchDown(onKnob: true, travel: travel, at: 0)
        _ = engine.touchMoved(along: 295, distance: 295, at: 0.1)
        XCTAssertTrue(engine.isArmed)
        let update = engine.touchCancelled(at: 0.2)
        XCTAssertNil(update.confirmedTrigger)
        XCTAssertEqual(engine.progress, 0)
    }

    func testResetFromAnyPhase() {
        var engine = makeEngine()
        _ = engine.activate(.keyboard, at: 0)
        advance(&engine, to: 1)
        _ = engine.finish(.success, at: 1)
        _ = engine.reset(at: 2)
        XCTAssertEqual(engine.phase, .idle)
        XCTAssertEqual(engine.progress, 0)
        XCTAssertNil(engine.nextDeadline)
    }

    // MARK: Settings

    func testSettingsAreSanitized() {
        let engine = makeEngine {
            $0.commitThreshold = 4
            $0.holdDuration = -1
            $0.fillDrainSpeed = 0
            $0.holdHapticMarks = -2
        }
        XCTAssertEqual(engine.settings.commitThreshold, 1)
        XCTAssertEqual(engine.settings.holdDuration, 0.05)
        XCTAssertEqual(engine.settings.fillDrainSpeed, 0.1)
        XCTAssertEqual(engine.settings.holdHapticMarks, 0)
    }

    func testLongerHoldDuration() {
        var engine = makeEngine { $0.holdDuration = 3; $0.holdDelay = 0.1 }
        _ = engine.touchDown(onKnob: false, travel: travel, at: 0)
        XCTAssertNil(advance(&engine, to: 3).confirmedTrigger)
        XCTAssertEqual(advance(&engine, to: 3.1).confirmedTrigger, .hold)
    }

    // MARK: Previews

    func testPreviewStates() {
        let settings = ConfirmEngine.Settings()
        XCTAssertEqual(ConfirmEngine.preview(.idle, settings: settings).snapshot(at: 0).label, .idle)

        let holding = ConfirmEngine.preview(.holding(progress: 0.76), settings: settings).snapshot(at: 99)
        XCTAssertEqual(holding.label, .holding)
        XCTAssertEqual(holding.progress, 0.76)
        XCTAssertTrue(holding.showsRing)

        let armed = ConfirmEngine.preview(.armed(), settings: settings).snapshot(at: 0)
        XCTAssertEqual(armed.label, .armed)
        XCTAssertTrue(armed.labelSitsBehindKnob)

        let failure = ConfirmEngine.preview(.failure(message: "Nope"), settings: settings).snapshot(at: 0)
        XCTAssertEqual(failure.failureMessage, "Nope")
        XCTAssertEqual(failure.knobIcon, .failure)

        let disabled = ConfirmEngine.preview(.disabled, settings: settings).snapshot(at: 0)
        XCTAssertFalse(disabled.isEnabled)

        var fillSettings = settings
        fillSettings.holdBehavior = .fill
        let fill = ConfirmEngine.preview(.holding(progress: 0.5), settings: fillSettings).snapshot(at: 0)
        XCTAssertEqual(fill.fillProgress, 0.5)
        XCTAssertEqual(fill.progress, 0)
    }
}
