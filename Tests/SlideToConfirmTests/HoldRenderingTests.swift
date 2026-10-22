#if canImport(SwiftUI) && (os(iOS) || os(macOS))
import SwiftUI
import XCTest
@testable import SlideToConfirm

@MainActor
final class HoldRenderingTests: XCTestCase {

    private let states: [HoldToConfirmPreviewState] = [
        .idle, .holding(progress: 0.3), .holding(), .processing, .success,
        .failure(), .failure(message: "Declined"), .disabled,
    ]

    private func render<V: View>(_ view: V) -> CGImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        return renderer.cgImage
    }

    func testEveryProgressStyleRendersEveryState() {
        for style in HoldToConfirmProgressStyle.allCases {
            for release in HoldToConfirmReleaseBehavior.allCases {
                for state in states {
                    let button = HoldToConfirmButton("Hold to send", systemImage: "paperplane.fill") {}
                        .holdToConfirmConfiguration { $0.progressStyle = style; $0.releaseBehavior = release }
                        .holdToConfirmPreviewState(state)
                    XCTAssertNotNil(render(button), "\(style) \(release) \(state)")
                }
            }
        }
    }

    func testEveryCompletionStyleRendersMidCelebration() {
        let configuration = HoldToConfirmConfiguration()
        let palette = configuration.theme.palette(for: .light)
        let engine = ConfirmEngine.preview(.success, settings: configuration.engineSettings)
        for style in HoldToConfirmCompletionStyle.allCases {
            for t in [0, 0.45, 1] as [CGFloat] {
                let renderer = HoldCircleRenderer(
                    celebration: t,
                    snapshot: engine.snapshot(at: 0),
                    configuration: configuration.with { $0.completionStyle = style },
                    palette: palette,
                    successLabel: Text(verbatim: "Sent"),
                    labelFont: .body,
                    morphLabelWidth: 40,
                    isAnimated: false
                )
                XCTAssertNotNil(render(renderer), "\(style) at \(t)")
            }
        }
    }

    func testLabelPositionsThemesAndRightToLeftRender() {
        let themes: [SlideToConfirmTheme] = [.standard, .brand, .destructive, .positive, .monochrome, .tinted(.orange)]
        for position in HoldToConfirmLabelPosition.allCases {
            for theme in themes {
                for scheme in [ColorScheme.light, .dark] {
                    let button = HoldToConfirmButton("اضغط مطولاً للإرسال", systemImage: "paperplane.fill") {}
                        .holdToConfirmConfiguration { $0.labelPosition = position; $0.theme = theme }
                        .holdToConfirmPreviewState(.holding())
                        .environment(\.layoutDirection, .rightToLeft)
                        .environment(\.colorScheme, scheme)
                    XCTAssertNotNil(render(button), "\(position) \(scheme)")
                }
            }
        }
    }

    func testVerticalBarPresetIsFortyEightPoints() throws {
        let button = HoldToConfirmButton("Hold to send") {}
            .holdToConfirmConfiguration(.verticalBar)
            .holdToConfirmPreviewState(.idle)
        let image = try XCTUnwrap(render(button))
        XCTAssertEqual(HoldToConfirmConfiguration.verticalBar.outerDiameter, 48)
        XCTAssertEqual(image.width, 96, "48 pt at 2x")
        XCTAssertEqual(image.height, 96)
    }

    func testDefaultCircleWithLabelBelow() throws {
        let button = HoldToConfirmButton("Hold") {}
            .holdToConfirmPreviewState(.idle)
        let image = try XCTUnwrap(render(button))
        XCTAssertEqual(image.width, 220, "110 pt ring at 2x; the short label is narrower")
        XCTAssertGreaterThan(image.height, 220 + 24, "the label sits below the ring")
    }

    func testPresetsRender() {
        let presets: [HoldToConfirmConfiguration] = [.default, .compact, .large, .verticalBar, .destructive]
        for preset in presets {
            let button = HoldToConfirmButton("Hold to confirm") {}
                .holdToConfirmConfiguration(preset)
                .holdToConfirmPreviewState(.holding())
            XCTAssertNotNil(render(button))
        }
    }

    func testEngineSettingsMatchTheButton() {
        let settings = HoldToConfirmConfiguration().engineSettings
        XCTAssertEqual(settings.holdBehavior, .fill)
        XCTAssertFalse(settings.allowsDragging)
        XCTAssertEqual(settings.holdDelay, 0.1)

        XCTAssertEqual(HoldToConfirmConfiguration().with { $0.releaseBehavior = .reset }.engineSettings.holdBehavior, .glide)
        XCTAssertEqual(HoldToConfirmConfiguration().with { $0.progressStyle = .segments }.engineSettings.holdHapticMarks, 11)
        XCTAssertEqual(
            HoldToConfirmConfiguration().with { $0.successBehavior = .reset(after: 1.5) }.engineSettings.successResetDelay,
            1.5
        )
    }

    func testPlacementsCoverEveryHandAndStayInTheNaturalZone() {
        XCTAssertEqual(HoldToConfirmPlacement.allCases.count, 7)
        let screen = CGSize(width: 393, height: 760)
        let item = CGSize(width: 110, height: 150)
        for placement in HoldToConfirmPlacement.allCases {
            let frame = placement.frame(in: screen, margin: 20)
            let insets = frame.insets
            let x: CGFloat
            switch frame.alignment.horizontal {
            case .leading: x = insets.leading + item.width / 2
            case .trailing: x = screen.width - insets.trailing - item.width / 2
            default: x = screen.width / 2
            }
            let y: CGFloat
            switch frame.alignment.vertical {
            case .bottom: y = screen.height - insets.bottom - item.height + item.width / 2
            default: y = (screen.height + insets.top - insets.bottom) / 2 - item.height / 2 + item.width / 2
            }
            for hand in placement.hand.map({ [$0] }) ?? ThumbReach.Hand.allCases {
                XCTAssertEqual(
                    ThumbReach.zone(at: CGPoint(x: x, y: y), in: screen, hand: hand),
                    .natural,
                    "\(placement) for the \(hand) hand"
                )
            }
            XCTAssertEqual(placement.mirrored.mirrored, placement)
        }
    }
}
#endif
