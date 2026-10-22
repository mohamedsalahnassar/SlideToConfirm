import XCTest
@testable import SlideToConfirm

/// The engine as ``HoldToConfirmButton`` drives it: no knob to drag, inside the circle reported as
/// distance 0, outside as a large distance.
final class HoldEngineTests: XCTestCase {

    private let outside = 1000.0

    private func makeEngine(_ configure: (inout ConfirmEngine.Settings) -> Void = { _ in }) -> ConfirmEngine {
        var settings = ConfirmEngine.Settings()
        settings.holdBehavior = .fill
        settings.allowsDragging = false
        settings.holdDuration = 1.2
        settings.holdDelay = 0.1
        settings.holdCancellationDistance = 1
        settings.dragActivationDistance = .greatestFiniteMagnitude
        settings.nudgeDuration = 0.9
        configure(&settings)
        return ConfirmEngine(settings: settings)
    }

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

    private func press(_ engine: inout ConfirmEngine, at time: TimeInterval) {
        _ = engine.touchDown(onKnob: false, travel: 1, at: time)
        _ = engine.touchMoved(along: 0, distance: 0, at: time)
    }

    func testHoldingThroughTheDurationConfirms() {
        var engine = makeEngine()
        press(&engine, at: 0)
        XCTAssertEqual(engine.interaction, .pending)

        let began = advance(&engine, to: 0.1)
        XCTAssertEqual(engine.interaction, .holding)
        XCTAssertEqual(began.hapticEvents, [.holdBegan])

        XCTAssertEqual(engine.snapshot(at: 0.7).fillProgress, 0.5, accuracy: 0.0001)

        let done = advance(&engine, to: 1.35)
        XCTAssertEqual(done.confirmedTrigger, .hold)
        XCTAssertEqual(engine.phase, .processing)
        XCTAssertEqual(done.hapticEvents.filter { if case .holdProgress = $0 { return true } else { return false } }.count, 3)
    }

    func testMovingWithinTheCircleKeepsHolding() {
        var engine = makeEngine()
        press(&engine, at: 0)
        advance(&engine, to: 0.5)
        _ = engine.touchMoved(along: 0, distance: 0, at: 0.6)
        XCTAssertEqual(engine.interaction, .holding)
        XCTAssertEqual(advance(&engine, to: 1.35).confirmedTrigger, .hold)
    }

    func testEarlyReleaseDrainsAndResumesFromThere() {
        var engine = makeEngine()
        press(&engine, at: 0)
        advance(&engine, to: 0.7)
        let release = engine.touchUp(at: 0.7)
        XCTAssertNil(release.confirmedTrigger)
        XCTAssertEqual(engine.interaction, .none)
        XCTAssertTrue(engine.isTimeDependent, "draining")

        // Drains three times faster than it filled: 0.5 → 0.25 in 0.1 s.
        XCTAssertEqual(engine.snapshot(at: 0.8).fillProgress, 0.25, accuracy: 0.0001)

        press(&engine, at: 0.8)
        advance(&engine, to: 0.9)
        XCTAssertEqual(engine.snapshot(at: 0.9).fillProgress, 0.25, accuracy: 0.0001, "resumes where the drain was")
        XCTAssertNil(advance(&engine, to: 1.75).confirmedTrigger)
        XCTAssertEqual(advance(&engine, to: 1.85).confirmedTrigger, .hold, "0.75 left takes 0.9 s")
    }

    func testResetReleaseSnapsProgressBack() {
        var engine = makeEngine { $0.holdBehavior = .glide }
        press(&engine, at: 0)
        advance(&engine, to: 0.7)
        XCTAssertEqual(engine.snapshot(at: 0.7).progress, 0.5, accuracy: 0.0001)
        let release = engine.touchUp(at: 0.7)
        XCTAssertEqual(release.animation, .spring)
        XCTAssertEqual(engine.progress, 0)
        XCTAssertFalse(engine.isTimeDependent)
    }

    func testSlidingOffTheCircleCancelsTheHold() {
        var engine = makeEngine()
        press(&engine, at: 0)
        advance(&engine, to: 0.7)
        _ = engine.touchMoved(along: 0, distance: outside, at: 0.7)
        XCTAssertEqual(engine.interaction, .none)
        XCTAssertFalse(engine.isTracking)
        XCTAssertNil(advance(&engine, to: 2).confirmedTrigger)
        XCTAssertEqual(engine.phase, .idle)
        XCTAssertEqual(engine.snapshot(at: 2).fillProgress, 0)
    }

    func testSlidingOffBeforeTheHoldStartsIsIgnoredWithoutAHint() {
        var engine = makeEngine()
        press(&engine, at: 0)
        _ = engine.touchMoved(along: 0, distance: outside, at: 0.05)
        XCTAssertEqual(engine.interaction, .none)
        XCTAssertEqual(engine.touchUp(at: 0.08).animation, .none, "no nudge for a scroll")
    }

    func testTapNudgesWithoutShowingProgress() {
        var engine = makeEngine()
        press(&engine, at: 0)
        let tap = engine.touchUp(at: 0.05)
        XCTAssertEqual(tap.animation, .nudge)
        XCTAssertEqual(engine.interaction, .nudging)
        XCTAssertEqual(engine.snapshot(at: 0.1).fillProgress, 0, "the circle shows no progress for a tap")

        advance(&engine, to: 0.96)
        XCTAssertEqual(engine.interaction, .none, "the hint lasts 0.9 s")
    }

    func testPressingDuringTheHintStartsAHold() {
        var engine = makeEngine()
        press(&engine, at: 0)
        _ = engine.touchUp(at: 0.05)
        press(&engine, at: 0.3)
        XCTAssertEqual(engine.interaction, .pending)
        XCTAssertEqual(advance(&engine, to: 1.65).confirmedTrigger, .hold)
    }

    func testSegmentHapticsFollowTheSegmentCount() {
        var engine = makeEngine { $0.holdHapticMarks = 11 }
        press(&engine, at: 0)
        let update = advance(&engine, to: 1.35)
        let ticks = update.hapticEvents.filter { if case .holdProgress = $0 { return true } else { return false } }
        XCTAssertEqual(ticks.count, 11, "one tick between each of 12 segments")
    }

    func testKeyboardActivationFillsThenConfirms() {
        var engine = makeEngine()
        let activate = engine.activate(.keyboard, at: 0)
        XCTAssertEqual(activate.animation, .snap)
        XCTAssertEqual(engine.snapshot(at: 0).progress, 1, "the circle shows full while it waits")
        XCTAssertEqual(advance(&engine, to: 0.4).confirmedTrigger, .keyboard)
    }

    func testFailureThenRetry() {
        var engine = makeEngine()
        press(&engine, at: 0)
        advance(&engine, to: 1.35)
        _ = engine.finish(.failure(message: "Declined"), at: 1.5)
        XCTAssertEqual(engine.phase, .failure)
        XCTAssertEqual(engine.failureMessage, "Declined")

        press(&engine, at: 1.8)
        XCTAssertEqual(engine.phase, .idle, "pressing again retries straight away")
        XCTAssertEqual(engine.interaction, .pending)
    }
}

final class ThumbReachTests: XCTestCase {

    private let phone = CGSize(width: 393, height: 852)

    func testRightThumbReachesTheLowerRight() {
        XCTAssertEqual(ThumbReach.zone(at: CGPoint(x: 300, y: 600), in: phone, hand: .right), .natural)
        XCTAssertEqual(ThumbReach.zone(at: CGPoint(x: 196, y: 760), in: phone, hand: .right), .natural)
    }

    func testTheFarTopCornerIsHard() {
        XCTAssertEqual(ThumbReach.zone(at: CGPoint(x: 30, y: 80), in: phone, hand: .right), .hard)
        XCTAssertEqual(ThumbReach.zone(at: CGPoint(x: 363, y: 80), in: phone, hand: .left), .hard)
    }

    func testTheUpperMiddleIsAStretch() {
        XCTAssertEqual(ThumbReach.zone(at: CGPoint(x: 330, y: 380), in: phone, hand: .right), .stretch)
    }

    func testTheCornerUnderTheThumbIsACurl() {
        XCTAssertEqual(ThumbReach.zone(at: CGPoint(x: 385, y: 840), in: phone, hand: .right), .stretch)
    }

    func testHandsMirror() {
        let point = CGPoint(x: 80, y: 600)
        let mirrored = CGPoint(x: phone.width - point.x, y: point.y)
        XCTAssertEqual(
            ThumbReach.zone(at: point, in: phone, hand: .left),
            ThumbReach.zone(at: mirrored, in: phone, hand: .right)
        )
        XCTAssertEqual(ThumbReach.Hand.left.opposite, .right)
    }

    func testZonesAreOrderedByEffort() {
        XCTAssertLessThan(ThumbReach.Zone.natural, .stretch)
        XCTAssertLessThan(ThumbReach.Zone.stretch, .hard)
    }
}
