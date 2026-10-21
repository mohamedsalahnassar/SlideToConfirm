#if canImport(SwiftUI) && (os(iOS) || os(macOS))
import SwiftUI
import XCTest
@testable import SlideToConfirm

@MainActor
final class RenderingTests: XCTestCase {

    private let states: [SlideToConfirmPreviewState] = [
        .idle, .dragging(), .armed(), .holding(progress: 0.3), .holding(), .processing, .success,
        .failure(), .failure(message: "Insufficient funds"), .disabled,
    ]

    private func render<V: View>(_ view: V) -> CGImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        return renderer.cgImage
    }

    func testEveryStateRendersInEveryDirection() {
        for direction in SlideToConfirmDirection.allCases {
            for behavior in SlideToConfirmHoldBehavior.allCases {
                for state in states {
                    let control = SlideToConfirm("Slide or hold to send") {}
                        .slideToConfirmConfiguration { $0.direction = direction; $0.holdBehavior = behavior }
                        .slideToConfirmPreviewState(state)
                        .frame(width: direction.isVertical ? nil : 360, height: direction.isVertical ? 300 : nil)
                    let image = render(control)
                    XCTAssertNotNil(image, "\(direction) \(behavior) \(state)")
                }
            }
        }
    }

    func testHorizontalControlSizesToThicknessAndCap() throws {
        let control = SlideToConfirm("Slide to pay") {}
            .slideToConfirmPreviewState(.idle)
            .frame(width: 900)
        let image = try XCTUnwrap(render(control))
        XCTAssertEqual(image.width, 1800)
        XCTAssertEqual(image.height, 120, "60 pt thick at 2x")
    }

    func testVerticalControlUsesThicknessAsWidth() throws {
        let control = SlideToConfirm("Slide down to send") {}
            .slideToConfirmConfiguration(.verticalBar)
            .slideToConfirmPreviewState(.holding())
            .frame(height: 300)
        let image = try XCTUnwrap(render(control))
        XCTAssertEqual(image.width, 112, "56 pt wide at 2x")
        XCTAssertEqual(image.height, 600)
    }

    func testThemesRightToLeftAndCustomKnobRender() {
        let themes: [SlideToConfirmTheme] = [.standard, .brand, .accent, .destructive, .positive, .monochrome, .tinted(.orange)]
        for theme in themes {
            for scheme in [ColorScheme.light, .dark] {
                let control = SlideToConfirm("اسحب أو اضغط مطولاً للإرسال") {}
                    .slideToConfirmTheme(theme)
                    .slideToConfirmPreviewState(.holding())
                    .slideToConfirmKnob { knob in
                        Image(systemName: "lock.fill").foregroundStyle(knob.iconColor)
                    }
                    .environment(\.layoutDirection, .rightToLeft)
                    .environment(\.colorScheme, scheme)
                    .frame(width: 360)
                XCTAssertNotNil(render(control))
            }
        }
    }

    func testAccessibilitySizesGrowTheTrack() throws {
        let control = SlideToConfirm("Slide to pay") {}
            .slideToConfirmPreviewState(.idle)
            .environment(\.dynamicTypeSize, .accessibility3)
            .frame(width: 360)
        let image = try XCTUnwrap(render(control))
        XCTAssertGreaterThan(image.height, 120)
    }
}
#endif
