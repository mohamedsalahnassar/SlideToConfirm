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
        let app = launch(["-debugReadout"])
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
        let released = NSPredicate(format: "label CONTAINS %@", "Released early")
        let result = XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: released, object: readout)], timeout: 4)
        XCTAssertEqual(result, .completed, "Readout “\(readout.label)”; delivered states: \(readout.value as? String ?? "?")")
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

        for tab in ["Playground", "States", "Scenarios"] {
            let button = app.tabBars.buttons[tab]
            XCTAssertTrue(button.waitForExistence(timeout: 10), "Missing tab \(tab)")
            button.tap()
        }

        for scenario in ["send", "unlock", "checkout", "delete", "sos", "garage", "uikit"] {
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
}

/// Records the README animation. Runs only when `RECORD_DEMO=1` is passed to the test runner.
final class DemoRecordingTests: XCTestCase {

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
