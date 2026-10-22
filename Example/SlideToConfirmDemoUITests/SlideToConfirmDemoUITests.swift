import XCTest

/// Drives the real control with touches: holding, dragging, releasing early and right-to-left.
final class SlideToConfirmDemoUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-screen", "record"] + arguments
        app.launch()
        return app
    }

    private func waitForReadout(_ app: XCUIApplication, containing text: String, timeout: TimeInterval = 8) {
        let readout = app.staticTexts["hero.readout"]
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: readout)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Readout was “\(readout.label)”, expected it to contain “\(text)”")
    }

    func testHoldingAnywhereConfirms() {
        let app = launch()
        let control = app.buttons["hero.control"]
        XCTAssertTrue(control.waitForExistence(timeout: 10))
        control.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5)).press(forDuration: 1.9)
        waitForReadout(app, containing: "by holding")
    }

    func testDraggingTheKnobConfirms() {
        let app = launch()
        let control = app.buttons["hero.control"]
        XCTAssertTrue(control.waitForExistence(timeout: 10))
        let knob = control.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5)).withOffset(CGVector(dx: 30, dy: 0))
        let end = control.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5)).withOffset(CGVector(dx: -6, dy: 0))
        knob.press(forDuration: 0.05, thenDragTo: end)
        waitForReadout(app, containing: "by dragging")
    }

    func testReleasingEarlySpringsBack() {
        let app = launch()
        let control = app.buttons["hero.control"]
        XCTAssertTrue(control.waitForExistence(timeout: 10))
        let readout = app.staticTexts["hero.readout"]
        // Several releases in a row: the last state reported must always be the release, never a
        // stale frame from the hold.
        for (attempt, duration) in [0.7, 0.5, 0.9].enumerated() {
            control.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5)).press(forDuration: duration)
            let released = NSPredicate(format: "label CONTAINS %@ AND NOT (label CONTAINS %@)", "Released early", "Holding")
            let result = XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: released, object: readout)], timeout: 4)
            XCTAssertEqual(result, .completed, "Attempt \(attempt + 1): readout was “\(readout.label)”")
        }
    }

    func testDraggingRightToLeftConfirmsInArabic() {
        let app = launch(["-language", "ar"])
        let control = app.buttons["hero.control"]
        XCTAssertTrue(control.waitForExistence(timeout: 10))
        let knob = control.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5)).withOffset(CGVector(dx: -30, dy: 0))
        let end = control.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5)).withOffset(CGVector(dx: 6, dy: 0))
        knob.press(forDuration: 0.05, thenDragTo: end)
        waitForReadout(app, containing: "by dragging")
    }

    /// The recording's sequence: confirm by holding, confirm by dragging, then release a hold early.
    func testEarlyReleaseAfterConfirmations() {
        let app = launch()
        let control = app.buttons["hero.control"]
        let readout = app.staticTexts["hero.readout"]
        XCTAssertTrue(control.waitForExistence(timeout: 10))

        control.coordinate(withNormalizedOffset: CGVector(dx: 0.62, dy: 0.5)).press(forDuration: 1.9)
        waitForReadout(app, containing: "by holding")
        waitForReadout(app, containing: "Try it again")

        let knob = control.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5)).withOffset(CGVector(dx: 30, dy: 0))
        let end = control.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5)).withOffset(CGVector(dx: -4, dy: 0))
        knob.press(forDuration: 0.08, thenDragTo: end, withVelocity: XCUIGestureVelocity(260), thenHoldForDuration: 0.35)
        waitForReadout(app, containing: "by dragging")
        waitForReadout(app, containing: "Try it again")

        control.coordinate(withNormalizedOffset: CGVector(dx: 0.62, dy: 0.5)).press(forDuration: 0.8)
        // Don't poll: the recording never touches the accessibility tree after the release either.
        Thread.sleep(forTimeInterval: 3)
        XCTAssertTrue(readout.label.contains("Released early"), "Readout was “\(readout.label)”")
    }

    func testControlIsAnAccessibleButton() {
        let app = launch()
        let control = app.buttons["hero.control"]
        XCTAssertTrue(control.waitForExistence(timeout: 10))
        XCTAssertEqual(control.label, "Slide or hold to send")
    }
}

/// Opens every tab and scenario to catch crashes and layout failures.
final class NavigationSmokeTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    func testEveryTabAndScenarioOpens() {
        let app = XCUIApplication()
        app.launch()

        for tab in ["Hold", "Playground", "States", "Scenarios"] {
            let button = app.tabBars.buttons[tab]
            XCTAssertTrue(button.waitForExistence(timeout: 10), "Missing tab \(tab)")
            button.tap()
        }

        for scenario in ["send", "unlock", "checkout", "delete", "sos", "garage", "workout", "uikit"] {
            let card = app.buttons["scenario.\(scenario)"]
            if !card.waitForExistence(timeout: 3) {
                app.swipeUp()
            }
            XCTAssertTrue(card.waitForExistence(timeout: 5), "Missing scenario \(scenario)")
            card.tap()
            XCTAssertTrue(app.navigationBars.buttons.firstMatch.waitForExistence(timeout: 5))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }

    func testEveryHoldScreenOpens() {
        let app = XCUIApplication()
        app.launch()
        let tab = app.tabBars.buttons["Hold"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10))
        tab.tap()
        XCTAssertTrue(app.buttons["hold.hero"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["hold.progress.liquid"].waitForExistence(timeout: 5))

        for route in ["hold-compose", "hold-reach"] {
            let link = app.buttons["hold.link.\(route)"]
            for _ in 0..<6 where !link.isHittable {
                app.swipeUp()
            }
            XCTAssertTrue(link.waitForExistence(timeout: 5), "Missing link \(route)")
            link.tap()
            XCTAssertTrue(app.navigationBars.buttons.firstMatch.waitForExistence(timeout: 5))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
}

/// Drives the circle with touches: holding, tapping, releasing early and sliding off.
final class HoldToConfirmUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ arguments: [String] = ["-screen", "record-hold"]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }

    private func waitForReadout(_ app: XCUIApplication, containing text: String, timeout: TimeInterval = 8) {
        let readout = app.staticTexts["hold.readout"]
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: readout)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Readout was “\(readout.label)”, expected it to contain “\(text)”")
    }

    func testHoldingConfirms() {
        let app = launch()
        let circle = app.buttons["hold.hero"]
        XCTAssertTrue(circle.waitForExistence(timeout: 10))
        circle.press(forDuration: 1.9)
        waitForReadout(app, containing: "by holding")
    }

    func testTappingShowsTheHint() {
        let app = launch()
        let circle = app.buttons["hold.hero"]
        XCTAssertTrue(circle.waitForExistence(timeout: 10))
        circle.tap()
        waitForReadout(app, containing: "That was a tap")
    }

    func testReleasingEarlyDrainsWithoutConfirming() {
        let app = launch()
        let circle = app.buttons["hold.hero"]
        XCTAssertTrue(circle.waitForExistence(timeout: 10))
        circle.press(forDuration: 0.7)
        waitForReadout(app, containing: "Let go early")
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertFalse(app.staticTexts["hold.readout"].label.contains("Sent"))
    }

    func testSlidingOffCancels() {
        let app = launch()
        let circle = app.buttons["hold.hero"]
        XCTAssertTrue(circle.waitForExistence(timeout: 10))
        let center = circle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let farAway = center.withOffset(CGVector(dx: 0, dy: 260))
        center.press(forDuration: 0.6, thenDragTo: farAway, withVelocity: .fast, thenHoldForDuration: 1.4)
        waitForReadout(app, containing: "Let go early")
        Thread.sleep(forTimeInterval: 1)
        XCTAssertFalse(app.staticTexts["hold.readout"].label.contains("Sent"))
    }

    func testCircleIsAnAccessibleButton() {
        let app = launch()
        let circle = app.buttons["hold.hero"]
        XCTAssertTrue(circle.waitForExistence(timeout: 10))
        XCTAssertEqual(circle.label, "Hold to send")
    }

    func testRingInTheVerticalBarSends() {
        let app = launch(["-screen", "tabzone", "-control", "ring", "-step", "review"])
        let ring = app.buttons["duo.control"]
        XCTAssertTrue(ring.waitForExistence(timeout: 10))
        ring.press(forDuration: 1.9)
        XCTAssertTrue(app.staticTexts["Sent"].waitForExistence(timeout: 8))
    }

    func testReachMapShowsAVerdict() {
        let app = launch(["-screen", "hold-reach", "-hand", "left", "-placement", "edge"])
        XCTAssertTrue(app.buttons["reach.control"].waitForExistence(timeout: 10))
        let verdict = app.descendants(matching: .any)["reach.verdict"]
        XCTAssertTrue(verdict.waitForExistence(timeout: 5))
        XCTAssertTrue(verdict.label.contains("left thumb"), verdict.label)
    }
}

/// Records the README animations. Runs only when `RECORD_DEMO=1` is passed to the test runner.
final class DemoRecordingTests: XCTestCase {

    /// Tells the recording script where the stage is and when the demo starts.
    private func writeStart(_ app: XCUIApplication, stage: XCUIElement, fallback: XCUIElement) throws {
        guard let path = ProcessInfo.processInfo.environment["RECORD_META"] else { return }
        let frame = stage.exists ? stage.frame : fallback.frame
        let meta = """
        {"start": \(Date().timeIntervalSince1970), "x": \(frame.minX), "y": \(frame.minY), "width": \(frame.width), "height": \(frame.height), "screenWidth": \(app.frame.width)}
        """
        try meta.write(toFile: path, atomically: true, encoding: .utf8)
    }

    private func writeEnd() throws {
        guard let path = ProcessInfo.processInfo.environment["RECORD_META"] else { return }
        try "\(Date().timeIntervalSince1970)".write(toFile: path + ".end", atomically: true, encoding: .utf8)
        // The simulator's video clock runs a little behind the wall clock, so stay on screen
        // past the end marker to keep the trimmed clip inside the app.
        Thread.sleep(forTimeInterval: 6)
    }

    func testRecordHoldDemo() throws {
        let environment = ProcessInfo.processInfo.environment
        try XCTSkipUnless(environment["RECORD_DEMO"] == "1", "Set TEST_RUNNER_RECORD_DEMO=1 to record.")

        let app = XCUIApplication()
        app.launchArguments = ["-screen", "record-hold", "-appearance", environment["RECORD_APPEARANCE"] ?? "light"]
        app.launch()
        let circle = app.buttons["hold.hero"]
        XCTAssertTrue(circle.waitForExistence(timeout: 15))
        let stage = app.otherElements["record.stage"]
        _ = stage.waitForExistence(timeout: 5)
        sleep(1)
        try writeStart(app, stage: stage, fallback: circle)

        // 1. A tap only shows the hint.
        Thread.sleep(forTimeInterval: 0.8)
        circle.tap()
        Thread.sleep(forTimeInterval: 1.8)

        // 2. Let go early: it drains back.
        circle.press(forDuration: 0.75)
        Thread.sleep(forTimeInterval: 1.8)

        // 3. Hold to the end: processing, then the circle morphs into "Sent" and resets.
        circle.press(forDuration: 1.7)
        Thread.sleep(forTimeInterval: 5.2)

        try writeEnd()
    }

    func testRecordDemo() throws {
        let environment = ProcessInfo.processInfo.environment
        try XCTSkipUnless(environment["RECORD_DEMO"] == "1", "Set TEST_RUNNER_RECORD_DEMO=1 to record.")

        let app = XCUIApplication()
        app.launchArguments = ["-screen", "record", "-appearance", environment["RECORD_APPEARANCE"] ?? "light"]
        app.launch()
        let control = app.buttons["hero.control"]
        XCTAssertTrue(control.waitForExistence(timeout: 15))
        let stage = app.otherElements["record.stage"]
        _ = stage.waitForExistence(timeout: 5)
        sleep(1)

        // Tell the workflow where the stage is and when the demo starts.
        if let path = environment["RECORD_META"] {
            let frame = stage.exists ? stage.frame : control.frame
            let meta = """
            {"start": \(Date().timeIntervalSince1970), "x": \(frame.minX), "y": \(frame.minY), "width": \(frame.width), "height": \(frame.height), "screenWidth": \(app.frame.width)}
            """
            try meta.write(toFile: path, atomically: true, encoding: .utf8)
        }

        // 1. Hold anywhere on the pill.
        Thread.sleep(forTimeInterval: 0.8)
        control.coordinate(withNormalizedOffset: CGVector(dx: 0.62, dy: 0.5)).press(forDuration: 1.9)
        Thread.sleep(forTimeInterval: 4.6)

        // 2. Drag the knob to the end.
        let knob = control.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5)).withOffset(CGVector(dx: 30, dy: 0))
        let end = control.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5)).withOffset(CGVector(dx: -4, dy: 0))
        knob.press(forDuration: 0.08, thenDragTo: end, withVelocity: XCUIGestureVelocity(260), thenHoldForDuration: 0.35)
        Thread.sleep(forTimeInterval: 4.6)

        // 3. Hold, then let go early: it springs back.
        control.coordinate(withNormalizedOffset: CGVector(dx: 0.62, dy: 0.5)).press(forDuration: 0.8)
        Thread.sleep(forTimeInterval: 2.2)

        if let path = environment["RECORD_META"] {
            try "\(Date().timeIntervalSince1970)".write(toFile: path + ".end", atomically: true, encoding: .utf8)
        }
        // The simulator's video clock runs a little behind the wall clock, so stay on screen
        // past the end marker to keep the trimmed clip inside the app.
        Thread.sleep(forTimeInterval: 6)
    }
}
