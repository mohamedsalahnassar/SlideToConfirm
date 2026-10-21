import XCTest
@testable import SlideToConfirm

final class TrackLayoutTests: XCTestCase {

    private let layout = TrackLayout(length: 360, thickness: 60, knobInset: 4)

    private func snapshot(
        phase: SlideToConfirmPhase = .idle,
        interaction: ConfirmEngine.Interaction = .none,
        hold: SlideToConfirmHoldBehavior = .combined,
        progress: Double = 0,
        fill: Double = 0,
        armed: Bool = false
    ) -> ConfirmSnapshot {
        ConfirmSnapshot(
            phase: phase, interaction: interaction, holdBehavior: hold, progress: progress,
            fillProgress: fill, ringProgress: 0, isArmed: armed, isEnabled: true, failureMessage: nil
        )
    }

    func testKnobGeometry() {
        XCTAssertEqual(layout.knobDiameter, 52)
        XCTAssertEqual(layout.travel, 300)
        XCTAssertEqual(layout.knobLeading(progress: 0), 4)
        XCTAssertEqual(layout.knobLeading(progress: 1), 304)
        XCTAssertEqual(layout.softFillLength(progress: 0), 60)
        XCTAssertEqual(layout.softFillLength(progress: 1), 360)
    }

    func testIdleLabelSitsAfterTheKnob() {
        let insets = layout.baseLabelInsets(snapshot())
        XCTAssertEqual(insets, .init(leading: 66, trailing: 20))
    }

    func testArmedLabelMovesBehindTheKnob() {
        let insets = layout.baseLabelInsets(snapshot(interaction: .dragging, progress: 1, armed: true))
        XCTAssertEqual(insets, .init(leading: 20, trailing: 66))
    }

    func testCombinedHoldSplitsTheTrackAroundTheKnob() {
        let s = snapshot(interaction: .holding, progress: 0.5)
        XCTAssertEqual(layout.baseLabelInsets(s), .init(leading: 60 + 150 + 6, trailing: 20))
        XCTAssertEqual(layout.revealLabelInsets(s), .init(leading: 20, trailing: 150 + 60 + 6))
        XCTAssertEqual(layout.solidFillLength(s), 210)
    }

    func testCombinedHoldHandsTheLabelOver() {
        let textLength = 120.0
        let early = layout.labelOpacities(snapshot(interaction: .holding, progress: 0.05), textLength: textLength)
        XCTAssertEqual(early.base, 1)
        XCTAssertEqual(early.reveal, 0)

        let late = layout.labelOpacities(snapshot(interaction: .holding, progress: 0.95), textLength: textLength)
        XCTAssertEqual(late.base, 0)
        XCTAssertEqual(late.reveal, 1)

        // Somewhere in between the two labels cross-fade, never both fully visible.
        for step in 0...100 {
            let o = layout.labelOpacities(snapshot(interaction: .holding, progress: Double(step) / 100), textLength: textLength)
            XCTAssertLessThanOrEqual(o.base + o.reveal, 1.0001, "at \(step)%")
        }
    }

    func testDragFadesTheLabel() {
        let o = layout.labelOpacities(snapshot(interaction: .dragging, progress: 0.25), textLength: 100)
        XCTAssertEqual(o.base, 0.4, accuracy: 0.0001)
        let gone = layout.labelOpacities(snapshot(interaction: .dragging, progress: 0.5), textLength: 100)
        XCTAssertEqual(gone.base, 0)
    }

    func testGlideBringsTheLabelBackBehindTheKnob() {
        let o = layout.labelOpacities(snapshot(interaction: .holding, hold: .glide, progress: 0.5), textLength: 100)
        XCTAssertEqual(o.base, 0.4, accuracy: 0.0001)
        let late = layout.labelOpacities(snapshot(interaction: .holding, hold: .glide, progress: 0.8), textLength: 100)
        XCTAssertEqual(late.base, 1)
    }

    func testFillLengthFollowsFillProgress() {
        let s = snapshot(interaction: .holding, hold: .fill, fill: 0.25)
        XCTAssertEqual(layout.solidFillLength(s), 90)
        XCTAssertEqual(layout.revealLabelInsets(s), layout.baseLabelInsets(s))
    }

    func testProcessingFillsTheTrack() {
        let s = snapshot(phase: .processing, progress: 1)
        XCTAssertTrue(s.showsSolidFill)
        XCTAssertFalse(s.showsRevealLabel)
        XCTAssertEqual(layout.solidFillLength(s), 360)
        XCTAssertEqual(layout.baseLabelInsets(s), .init(leading: 20, trailing: 66))
    }

    func testSuccessHidesFills() {
        let s = snapshot(phase: .success, progress: 1)
        XCTAssertFalse(s.showsSolidFill)
        XCTAssertFalse(s.showsSoftFill)
    }

    func testShortTrackNeverHasNegativeTravel() {
        let tiny = TrackLayout(length: 40, thickness: 60, knobInset: 4)
        XCTAssertEqual(tiny.travel, 0)
        XCTAssertEqual(tiny.knobLeading(progress: 1), 4)
    }
}
