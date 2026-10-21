#if canImport(SwiftUI) && (os(iOS) || os(macOS))
import ImageIO
import SwiftUI
import UniformTypeIdentifiers
import XCTest
@testable import SlideToConfirm

/// Renders the component images in the README from the real control.
///
/// Runs only when `SLIDETOCONFIRM_RENDER_DIR` is set (prefix it with `TEST_RUNNER_` for `xcodebuild`):
///
///     TEST_RUNNER_SLIDETOCONFIRM_RENDER_DIR=$PWD/docs/images xcodebuild test -scheme SlideToConfirm …
@MainActor
final class ReadmeImageTests: XCTestCase {

    private var outputDirectory: URL!

    override func setUpWithError() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let path = environment["SLIDETOCONFIRM_RENDER_DIR"], !path.isEmpty else {
            throw XCTSkip("Set SLIDETOCONFIRM_RENDER_DIR to render README images.")
        }
        outputDirectory = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    }

    private func save<V: View>(_ view: V, as name: String) throws {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        let image = try XCTUnwrap(renderer.cgImage, "Could not render \(name)")
        let url = outputDirectory.appendingPathComponent("\(name).png")
        let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination), "Could not write \(url.path)")
    }

    func testRenderStatesGrid() throws {
        try save(StatesGrid(), as: "states")
    }

    func testRenderHoldBehaviors() throws {
        try save(HoldBehaviorsCard(scheme: .light), as: "hold-behaviors-light")
        try save(HoldBehaviorsCard(scheme: .dark), as: "hold-behaviors-dark")
    }

    func testRenderThemes() throws {
        try save(ThemesCard(scheme: .light), as: "themes-light")
        try save(ThemesCard(scheme: .dark), as: "themes-dark")
    }

    func testRenderDirections() throws {
        try save(DirectionsCard(scheme: .light), as: "directions-light")
        try save(DirectionsCard(scheme: .dark), as: "directions-dark")
    }

    func testRenderCustomization() throws {
        try save(CustomizationCard(scheme: .light), as: "customization-light")
        try save(CustomizationCard(scheme: .dark), as: "customization-dark")
    }

    func testRenderHero() throws {
        try save(HeroCard(scheme: .light), as: "hero-light")
        try save(HeroCard(scheme: .dark), as: "hero-dark")
    }
}

// MARK: - Compositions

private enum Palette {
    static func background(_ scheme: ColorScheme) -> Color { scheme == .dark ? Color(stcHex: 0x07090F) : Color(stcHex: 0xF5F6F9) }
    static func card(_ scheme: ColorScheme) -> Color { scheme == .dark ? Color(stcHex: 0x121724) : .white }
    static func line(_ scheme: ColorScheme) -> Color { scheme == .dark ? Color(stcHex: 0x222A3B) : Color(stcHex: 0xE3E7EF) }
    static func ink(_ scheme: ColorScheme) -> Color { scheme == .dark ? Color(stcHex: 0xF3F5FA) : Color(stcHex: 0x0E1220) }
    static func ink2(_ scheme: ColorScheme) -> Color { scheme == .dark ? Color(stcHex: 0xA3AABF) : Color(stcHex: 0x555D74) }
    static let brand = Color(stcHex: 0x13246F)
}

private let sendLabels = SlideToConfirmLabels(
    "Slide or hold to send",
    armed: "Release to send",
    holding: "Keep holding…",
    processing: "Sending…",
    success: "Sent",
    failure: "Not sent · try again"
)

private struct Caption: View {
    let title: String
    var detail: String?
    let scheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.ink(scheme))
            if let detail {
                Text(verbatim: detail).font(.system(size: 12.5)).foregroundStyle(Palette.ink2(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct Board<Content: View>: View {
    let scheme: ColorScheme
    var width: CGFloat = 820
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(28)
            .frame(width: width)
            .background(Palette.background(scheme))
            .environment(\.colorScheme, scheme)
    }
}

private struct StatesGrid: View {
    private let rows: [(SlideToConfirmPreviewState, String, String)] = [
        (.idle, "Idle", "Shimmer runs toward the end."),
        (.holding(progress: 0.24), "Holding · early", "The knob glides; the solid fill follows."),
        (.holding(progress: 0.76), "Holding · late", "The label hands over to the fill."),
        (.dragging(progress: 0.46), "Dragging", "A softer fill follows the finger."),
        (.armed(progress: 0.94), "Armed", "Past 90%: release to send."),
        (.processing, "Processing", "Locked until the action returns."),
        (.success, "Success", "Green only after success."),
        (.failure(), "Failure", "Shake, error haptic, back to idle."),
        (.disabled, "Disabled", "Until the form is valid."),
    ]

    private let surfaces: [(String, Color, ColorScheme, SlideToConfirmTheme)] = [
        ("LIGHT", Color(stcHex: 0xF2F4F8), .light, .standard),
        ("DARK", Color(stcHex: 0x07090F), .dark, .standard),
        ("BRAND SURFACE", Palette.brand, .dark, .brand),
    ]

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                Text(verbatim: "STATE")
                    .font(.system(size: 11.5, weight: .semibold)).tracking(0.8)
                    .foregroundStyle(Color(stcHex: 0x8A91A6))
                    .frame(width: 210, alignment: .leading)
                    .padding(.horizontal, 18).padding(.vertical, 14)
                    .background(Color.white)
                ForEach(Array(surfaces.enumerated()), id: \.offset) { _, surface in
                    Text(verbatim: surface.0)
                        .font(.system(size: 11.5, weight: .semibold)).tracking(0.8)
                        .foregroundStyle(surface.2 == .light ? Color(stcHex: 0x555D74) : .white.opacity(0.7))
                        .frame(width: 330, alignment: .leading)
                        .padding(.horizontal, 18).padding(.vertical, 14)
                        .background(surface.1)
                }
            }
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: row.1).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(stcHex: 0x0E1220))
                        Text(verbatim: row.2).font(.system(size: 12.5)).foregroundStyle(Color(stcHex: 0x555D74))
                    }
                    .frame(width: 210, alignment: .leading)
                    .padding(.horizontal, 18)
                    .frame(maxHeight: .infinity)
                    .background(Color.white)
                    .overlay(alignment: .top) { Rectangle().fill(Color(stcHex: 0xE3E7EF)).frame(height: 1) }
                    ForEach(Array(surfaces.enumerated()), id: \.offset) { _, surface in
                        SlideToConfirm(labels: sendLabels) {}
                            .slideToConfirmTheme(surface.3)
                            .slideToConfirmPreviewState(row.0)
                            .environment(\.colorScheme, surface.2)
                            .frame(width: 330)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(surface.1)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(24)
        .background(Color(stcHex: 0xF5F6F9))
    }
}

private struct HoldBehaviorsCard: View {
    let scheme: ColorScheme

    var body: some View {
        Board(scheme: scheme, width: 980) {
            VStack(spacing: 14) {
                row(.combined, "Combined", "The knob glides and a solid fill follows it. Recommended.")
                row(.fill, "Fill", "The knob stays put; the track fills behind the label.")
                row(.glide, "Glide", "The knob glides with the soft drag fill.")
            }
        }
    }

    private func row(_ behavior: SlideToConfirmHoldBehavior, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 18) {
            Caption(title: title, detail: detail, scheme: scheme)
                .frame(width: 190, alignment: .leading)
            SlideToConfirm(labels: sendLabels) {}
                .slideToConfirmPreviewState(.holding(progress: behavior == .fill ? 0.3 : 0.14))
            SlideToConfirm(labels: sendLabels) {}
                .slideToConfirmPreviewState(.holding(progress: behavior == .fill ? 0.72 : 0.84))
        }
        .slideToConfirmHoldBehavior(behavior)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.card(scheme), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.line(scheme)))
    }
}

private struct ThemesCard: View {
    let scheme: ColorScheme

    var body: some View {
        Board(scheme: scheme) {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    sample(".standard", theme: .standard, state: .holding(progress: 0.62))
                    sample(".positive", theme: .positive, state: .success, labels: SlideToConfirmLabels("Slide to unlock", success: "Unlocked"))
                }
                HStack(spacing: 14) {
                    sample(".destructive", theme: .destructive, state: .holding(progress: 0.55), labels: SlideToConfirmLabels("Hold to delete", holding: "Keep holding…"))
                    sample(".monochrome", theme: .monochrome, state: .idle, labels: SlideToConfirmLabels("Slide to sign"))
                }
                HStack(spacing: 14) {
                    sample(".tinted(.orange)", theme: .tinted(.orange), state: .armed(), labels: SlideToConfirmLabels("Slide to start", armed: "Release to start"))
                    VStack(alignment: .leading, spacing: 10) {
                        Text(verbatim: ".brand / .onColor(_:)").font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.85))
                        SlideToConfirm(labels: sendLabels) {}
                            .slideToConfirmTheme(.brand)
                            .slideToConfirmPreviewState(.holding(progress: 0.62))
                    }
                    .padding(16)
                    .background(
                        LinearGradient(colors: [Color(stcHex: 0x2343D6), Palette.brand], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                }
            }
        }
    }

    private func sample(_ name: String, theme: SlideToConfirmTheme, state: SlideToConfirmPreviewState, labels: SlideToConfirmLabels = sendLabels) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: name).font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundStyle(Palette.ink2(scheme))
            SlideToConfirm(labels: labels) {}
                .slideToConfirmTheme(theme)
                .slideToConfirmPreviewState(state)
        }
        .padding(16)
        .background(Palette.card(scheme), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.line(scheme)))
    }
}

private struct DirectionsCard: View {
    let scheme: ColorScheme

    private let arabic = SlideToConfirmLabels(
        idle: Text(verbatim: "اسحب أو اضغط مطولاً للإرسال"),
        armed: Text(verbatim: "اترك للإرسال"),
        holding: Text(verbatim: "استمر بالضغط…")
    )

    var body: some View {
        Board(scheme: scheme) {
            HStack(alignment: .top, spacing: 18) {
                HStack(alignment: .bottom, spacing: 16) {
                    vertical(.down, .idle, "Down")
                    vertical(.down, .holding(progress: 0.62), "Holding")
                    vertical(.up, .armed(), "Up")
                }
                .padding(16)
                .background(Palette.card(scheme), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.line(scheme)))

                VStack(alignment: .leading, spacing: 14) {
                    Caption(title: "Right to left", detail: "The knob starts on the right and slides left. Text never mirrors.", scheme: scheme)
                    SlideToConfirm(labels: arabic) {}
                        .slideToConfirmPreviewState(.idle)
                    SlideToConfirm(labels: arabic) {}
                        .slideToConfirmPreviewState(.holding(progress: 0.7))
                    SlideToConfirm(labels: arabic) {}
                        .slideToConfirmPreviewState(.armed())
                }
                .environment(\.layoutDirection, .rightToLeft)
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Palette.card(scheme), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.line(scheme)))
            }
        }
    }

    private func vertical(_ direction: SlideToConfirmDirection, _ state: SlideToConfirmPreviewState, _ caption: String) -> some View {
        VStack(spacing: 10) {
            SlideToConfirm(labels: sendLabels) {}
                .slideToConfirmConfiguration(.verticalBar.with { $0.direction = direction })
                .slideToConfirmPreviewState(state)
                .frame(height: 280)
            Text(verbatim: caption).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink2(scheme))
        }
    }
}

private struct CustomizationCard: View {
    let scheme: ColorScheme

    var body: some View {
        Board(scheme: scheme) {
            VStack(alignment: .leading, spacing: 18) {
                row("compact · 48 pt") {
                    SlideToConfirm(labels: SlideToConfirmLabels("Slide to approve", armed: "Release to approve")) {}
                        .slideToConfirmConfiguration(.compact)
                        .slideToConfirmPreviewState(.armed())
                }
                row("large · 72 pt · SF Symbol knob") {
                    SlideToConfirm("Hold for 3 s to send SOS") {}
                        .slideToConfirmConfiguration(.large.with {
                            $0.theme = .destructive
                            $0.holdBehavior = .fill
                            $0.icons.idle = .systemImage("sos")
                        })
                        .slideToConfirmPreviewState(.holding(progress: 0.45))
                }
                row("cornerRadius: 14 · arrow icon") {
                    SlideToConfirm("Slide to check out") {}
                        .slideToConfirmConfiguration {
                            $0.cornerRadius = 14
                            $0.icons.idle = .arrow
                            $0.theme = .tinted(Color(stcHex: 0x7C3AED))
                        }
                        .slideToConfirmPreviewState(.holding(progress: 0.58))
                }
                row("slideToConfirmKnob { … } · custom knob") {
                    SlideToConfirm("Slide to unlock") {}
                        .slideToConfirmConfiguration(.slideOnly.with { $0.theme = .positive })
                        .slideToConfirmKnob { knob in
                            Image(systemName: knob.state.phase == .success ? "lock.open.fill" : "lock.fill")
                                .font(.system(size: knob.diameter * 0.36, weight: .bold))
                                .foregroundStyle(knob.iconColor)
                        }
                        .slideToConfirmPreviewState(.idle)
                }
                row("failure with a reason") {
                    SlideToConfirm(labels: sendLabels) {}
                        .slideToConfirmPreviewState(.failure(message: "Not sent · insufficient funds"))
                }
            }
        }
    }

    private func row<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: title).font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundStyle(Palette.ink2(scheme))
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.card(scheme), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.line(scheme)))
    }
}

private struct HeroCard: View {
    let scheme: ColorScheme

    var body: some View {
        Board(scheme: scheme, width: 900) {
            VStack(spacing: 16) {
                SlideToConfirm(labels: sendLabels) {}
                    .slideToConfirmPreviewState(.idle)
                SlideToConfirm(labels: sendLabels) {}
                    .slideToConfirmPreviewState(.holding(progress: 0.66))
                SlideToConfirm(labels: sendLabels) {}
                    .slideToConfirmPreviewState(.success)
            }
            .padding(.vertical, 36)
            .frame(maxWidth: .infinity)
            .background(Palette.card(scheme), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Palette.line(scheme)))
        }
    }
}
#endif
