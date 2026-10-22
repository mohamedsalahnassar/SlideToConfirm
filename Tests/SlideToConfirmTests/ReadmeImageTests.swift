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

    func testRenderHoldToConfirm() throws {
        for scheme in [ColorScheme.light, .dark] {
            let suffix = scheme == .dark ? "dark" : "light"
            try save(HoldHeroCard(scheme: scheme), as: "hold-hero-\(suffix)")
            try save(HoldProgressStylesCard(scheme: scheme), as: "hold-progress-\(suffix)")
            try save(HoldCompletionStylesCard(scheme: scheme), as: "hold-completion-\(suffix)")
            try save(HoldStatesCard(scheme: scheme), as: "hold-states-\(suffix)")
            try save(HoldPlacementsCard(scheme: scheme), as: "hold-placements-\(suffix)")
            try save(HoldDuoCard(scheme: scheme), as: "hold-duo-\(suffix)")
        }
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

// MARK: - Hold to confirm

private let holdLabels = SlideToConfirmLabels(
    "Hold to send",
    holding: "Keep holding…",
    processing: "Sending…",
    success: "Sent",
    failure: "Not sent"
)

private struct Tile<Content: View>: View {
    let scheme: ColorScheme
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.card(scheme), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.line(scheme)))
    }
}

private struct HoldHeroCard: View {
    let scheme: ColorScheme

    var body: some View {
        Board(scheme: scheme, width: 900) {
            HStack(alignment: .top, spacing: 44) {
                button(.idle)
                button(.holding(progress: 0.62))
                button(.processing)
                button(.success)
            }
            .padding(.vertical, 36)
            .frame(maxWidth: .infinity)
            .background(Palette.card(scheme), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Palette.line(scheme)))
        }
    }

    private func button(_ state: HoldToConfirmPreviewState) -> some View {
        HoldToConfirmButton(labels: holdLabels, systemImage: "paperplane.fill") {}
            .holdToConfirmPreviewState(state)
    }
}

private struct HoldProgressStylesCard: View {
    let scheme: ColorScheme

    private let details: [HoldToConfirmProgressStyle: String] = [
        .ring: "A ring fills clockwise",
        .segments: "Ticks light up in step with haptics",
        .fill: "Fills from the bottom up",
        .liquid: "Fills with a moving wave",
        .radial: "A disc grows from the center",
        .pie: "A sector sweeps like a clock",
        .pulse: "Ripples speed up toward the end",
        .glow: "A halo grows brighter",
        .orbit: "A comet orbits, its tail growing",
        .countdown: "Seconds left count down",
    ]

    var body: some View {
        Board(scheme: scheme, width: 980) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 5), spacing: 14) {
                ForEach(HoldToConfirmProgressStyle.allCases) { style in
                    Tile(scheme: scheme) {
                        VStack(spacing: 14) {
                            HoldToConfirmButton(labels: holdLabels, systemImage: "paperplane.fill") {}
                                .holdToConfirmConfiguration { $0.progressStyle = style; $0.labelPosition = .hidden }
                                .holdToConfirmPreviewState(.holding(progress: style == .countdown ? 0.3 : 0.6))
                                .frame(height: 140)
                            Caption(title: ".\(style.rawValue)", detail: details[style], scheme: scheme)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }
}

private struct HoldCompletionStylesCard: View {
    let scheme: ColorScheme

    private let frames: [(HoldToConfirmCompletionStyle, CGFloat, String)] = [
        (.checkmark, 1, "Turns green with a check"),
        (.ripple, 0.32, "A shock wave rings out"),
        (.burst, 0.4, "Particles burst outward"),
        (.bounce, 0.5, "Pops with an overshoot"),
        (.morph, 1, "Stretches into a capsule"),
        (.flip, 0.82, "Flips to the success face"),
    ]

    var body: some View {
        let configuration = HoldToConfirmConfiguration()
        let engine = ConfirmEngine.preview(.success, settings: configuration.engineSettings)
        Board(scheme: scheme, width: 980) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
                ForEach(frames, id: \.0) { frame in
                    let (style, t, detail) = frame
                    Tile(scheme: scheme) {
                        VStack(spacing: 14) {
                            HoldCircleRenderer(
                                celebration: t,
                                snapshot: engine.snapshot(at: 0),
                                configuration: configuration.with { $0.completionStyle = style },
                                palette: configuration.theme.palette(for: scheme),
                                successLabel: Text(verbatim: "Sent"),
                                labelFont: .system(size: 15, weight: .semibold),
                                morphLabelWidth: 36,
                                isAnimated: false
                            )
                            .frame(width: 200, height: 170)
                            Caption(title: ".\(style.rawValue)", detail: detail, scheme: scheme)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }
}

private struct HoldStatesCard: View {
    let scheme: ColorScheme

    private let states: [(HoldToConfirmPreviewState, String)] = [
        (.idle, "Idle"),
        (.holding(progress: 0.35), "Holding"),
        (.processing, "Processing"),
        (.success, "Success"),
        (.failure(), "Failure"),
        (.disabled, "Disabled"),
    ]

    var body: some View {
        Board(scheme: scheme, width: 980) {
            HStack(alignment: .top, spacing: 14) {
                ForEach(Array(states.enumerated()), id: \.offset) { _, item in
                    Tile(scheme: scheme) {
                        VStack(spacing: 12) {
                            Text(verbatim: item.1.uppercased())
                                .font(.system(size: 11, weight: .semibold)).tracking(0.8)
                                .foregroundStyle(Palette.ink2(scheme))
                            HoldToConfirmButton(labels: holdLabels, systemImage: "paperplane.fill") {}
                                .holdToConfirmConfiguration(.compact)
                                .holdToConfirmPreviewState(item.0)
                        }
                        .frame(height: 130, alignment: .top)
                    }
                }
            }
        }
    }
}

/// A phone screen with a thumb-reach heat map and every placement for one hand.
private struct HoldPlacementsCard: View {
    let scheme: ColorScheme

    var body: some View {
        Board(scheme: scheme, width: 980) {
            HStack(alignment: .top, spacing: 28) {
                phone(hand: .right)
                phone(hand: .left)
                VStack(alignment: .leading, spacing: 16) {
                    legend(.green, "Natural", "Reached without shifting the grip.")
                    legend(.yellow, "Stretch", "Reached by stretching or curling the thumb.")
                    legend(.red, "Hard", "Needs the other hand.")
                    Divider().overlay(Palette.line(scheme))
                    Caption(title: "1  .bottomCenter", detail: "Either hand; where people look first.", scheme: scheme)
                    Caption(title: "2  .bottomCorner(hand)", detail: "Where floating buttons live.", scheme: scheme)
                    Caption(title: "3  .thumbArc(hand)", detail: "Where the thumb rests. Best for a hold.", scheme: scheme)
                    Caption(title: "4  .edge(hand)", detail: "Where the thumb wraps the phone; frees the bottom.", scheme: scheme)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            }
        }
    }

    private func phone(hand: ThumbReach.Hand) -> some View {
        VStack(spacing: 10) {
            ZStack(alignment: .top) {
                Palette.card(scheme)
                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 6).fill(Palette.line(scheme)).frame(width: 120, height: 18)
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12).fill(Palette.line(scheme).opacity(0.6)).frame(height: 54)
                    }
                }
                .padding(18)
                .padding(.top, 30)
                ThumbReachOverlay(hand: hand, opacity: scheme == .dark ? 0.22 : 0.28)
            }
            .holdToConfirmOverlay(.bottomCenter, margin: 16) { marker(1) }
            .holdToConfirmOverlay(.bottomCorner(hand), margin: 16) { marker(2) }
            .holdToConfirmOverlay(.thumbArc(hand), margin: 16) { marker(3) }
            .holdToConfirmOverlay(.edge(hand), margin: 16) { marker(4) }
            .frame(width: 280, height: 600)
            .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).strokeBorder(Palette.ink(scheme).opacity(0.85), lineWidth: 6))
            Text(verbatim: hand == .right ? "Right hand" : "Left hand")
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.ink2(scheme))
        }
    }

    private func marker(_ number: Int) -> some View {
        HoldToConfirmButton("Hold", systemImage: "hand.tap.fill") {}
            .holdToConfirmConfiguration(.verticalBar.with { $0.showsShadow = true })
            .holdToConfirmPreviewState(number == 3 ? .holding(progress: 0.6) : .idle)
            .overlay(alignment: .topTrailing) {
                Text(verbatim: "\(number)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(Palette.ink(scheme), in: Circle())
                    .offset(x: 4, y: -4)
            }
    }

    private func legend(_ color: Color, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.55)).frame(width: 16, height: 16).padding(.top, 2)
            Caption(title: title, detail: detail, scheme: scheme)
        }
    }
}

/// The ring in iPhone Duo's trailing vertical bar, in three positions.
private struct HoldDuoCard: View {
    let scheme: ColorScheme

    enum Variant { case tabZone, aboveTabs, thumbHeight }

    var body: some View {
        Board(scheme: scheme, width: 980) {
            HStack(alignment: .top, spacing: 18) {
                device(.tabZone, "In the tab zone", "Tabs hidden on Review; the ring takes their place under the thumb.")
                device(.aboveTabs, "Above minimized tabs", "The current tab stays one tap away below the ring.")
                device(.thumbHeight, "At thumb height", "Mid-bar, where the thumb wraps the edge. Tabs stay put.")
            }
        }
    }

    private func device(_ variant: Variant, _ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(verbatim: "Review").font(.system(size: 20, weight: .bold)).foregroundStyle(Palette.ink(scheme))
                    Text(verbatim: "AED 2,500.00").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(Palette.ink(scheme))
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 10).fill(Palette.line(scheme).opacity(0.7)).frame(height: 40)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                bar(variant)
                    .frame(width: 72)
            }
            .frame(width: 290, height: 470)
            .background(Palette.background(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).strokeBorder(Palette.ink(scheme).opacity(0.85), lineWidth: 5))
            Caption(title: title, detail: detail, scheme: scheme)
                .frame(width: 290, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    private func bar(_ variant: Variant) -> some View {
        VStack(spacing: 12) {
            glass("chevron.left").padding(.top, 14)
            Spacer(minLength: 0)
            if variant == .thumbHeight {
                ring
                Spacer(minLength: 0)
                    .frame(maxHeight: 70)
            }
            if variant == .aboveTabs { ring }
            switch variant {
            case .tabZone: ring.padding(.bottom, 4)
            case .aboveTabs: tabs(minimized: true)
            case .thumbHeight: tabs(minimized: false)
            }
        }
        .padding(.bottom, 16)
    }

    private var ring: some View {
        HoldToConfirmButton(labels: holdLabels, systemImage: "paperplane.fill") {}
            .holdToConfirmConfiguration(.verticalBar)
            .holdToConfirmPreviewState(.holding(progress: 0.62))
            .padding(4)
            .background(Palette.card(scheme), in: Circle())
            .overlay(Circle().strokeBorder(Palette.line(scheme)))
    }

    private func glass(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Palette.ink(scheme))
            .frame(width: 44, height: 44)
            .background(Palette.card(scheme), in: Circle())
            .overlay(Circle().strokeBorder(Palette.line(scheme)))
    }

    private func tabs(minimized: Bool) -> some View {
        let symbols = minimized ? ["arrow.left.arrow.right"] : ["house", "wallet.pass", "arrow.left.arrow.right", "creditcard"]
        return VStack(spacing: 2) {
            ForEach(symbols, id: \.self) { symbol in
                let selected = symbol == "arrow.left.arrow.right"
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(selected ? Color.white : Palette.ink(scheme))
                    .frame(width: 40, height: 40)
                    .background(selected ? Color(stcHex: 0x2343D6) : .clear, in: Circle())
            }
        }
        .padding(.vertical, 6)
        .frame(width: 52)
        .background(Palette.card(scheme), in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.line(scheme)))
    }
}
#endif
