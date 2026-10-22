import SlideToConfirm
import SwiftUI

/// Screens reachable from the Hold tab. Raw values double as `-screen` launch arguments.
enum HoldRoute: String, Hashable, CaseIterable {
    case compose = "hold-compose"
    case reach = "hold-reach"
    case duo = "hold-duo"
}

/// The circular variant: a live hero, every progress and completion style, and links to the
/// composer, the reach map and the iPhone Duo side bar.
struct HoldView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $model.holdPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 36) {
                    header
                    HoldHeroStage()
                    progressGallery
                    completionGallery
                    explore
                }
                .padding(.horizontal, DS.gutter)
                .padding(.top, 8)
                .padding(.bottom, 40)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .background(DS.background.ignoresSafeArea())
            .navigationTitle("Hold")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { AppSettingsMenu() }
            }
            .navigationDestination(for: HoldRoute.self) { route in
                switch route {
                case .compose: HoldComposerView()
                case .reach: ReachMapView()
                case .duo: TabZoneScenario(control: .ring)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("HoldToConfirmButton")
            Text("Just a circle. Press and hold it.")
                .font(.dsDisplay)
                .tracking(-1)
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("The same engine as the pill, without the track. It fits a floating corner, a toolbar or a 56 pt side bar. Let go early and it drains back; press again to pick up where it was.")
                .font(.dsLead)
                .foregroundStyle(DS.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var progressGallery: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                eyebrow: "While you hold",
                title: "Ten ways to show the countdown",
                lead: "Each one is live. Ring and Segments read best; Glow is the calmest. Fill styles redraw the icon so it changes color exactly where the fill reaches."
            )
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                ForEach(HoldToConfirmProgressStyle.allCases) { style in
                    GalleryCell(title: HoldText.title(for: style)) {
                        HoldToConfirmButton(labels: .holdSend, systemImage: "paperplane.fill") {
                            try await Task.sleep(for: .seconds(0.8))
                        }
                        .holdToConfirmConfiguration(.compact.with {
                            $0.progressStyle = style
                            $0.labelPosition = .hidden
                            $0.successBehavior = .reset(after: 1.2)
                        })
                        .accessibilityIdentifier("hold.progress.\(style.rawValue)")
                    }
                }
            }
        }
    }

    private var completionGallery: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                eyebrow: "When it's done",
                title: "Six ways to celebrate",
                lead: "Success shows only after your action returns. With Reduce Motion on, every style jumps straight to its final frame."
            )
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                ForEach(HoldToConfirmCompletionStyle.allCases) { style in
                    GalleryCell(title: HoldText.title(for: style)) {
                        HoldToConfirmButton(labels: .holdSend, systemImage: "paperplane.fill") {
                            try await Task.sleep(for: .seconds(0.6))
                        }
                        .holdToConfirmConfiguration(.compact.with {
                            $0.completionStyle = style
                            $0.labelPosition = .hidden
                            $0.holdDuration = 0.8
                            $0.successBehavior = .reset(after: 1.6)
                        })
                        .accessibilityIdentifier("hold.completion.\(style.rawValue)")
                    }
                }
            }
        }
    }

    private var explore: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(eyebrow: "Explore", title: "Make it yours, put it in reach")
            VStack(spacing: 12) {
                link(.compose, symbol: "slider.horizontal.3", colors: [Color(hex: 0x4C6BFF), Color(hex: 0x2343D6)],
                     title: "Composer", detail: "Every option, live, with the code to copy.")
                link(.reach, symbol: "hand.point.up.left.fill", colors: [Color(hex: 0x34C77B), Color(hex: 0x16884A)],
                     title: "Thumb reach", detail: "Seven placements over a reach heat map, for either hand.")
                link(.duo, symbol: "sidebar.right", colors: [Color(hex: 0x5B77FF), Color(hex: 0x13246F)],
                     title: "iPhone Duo side bar", detail: "A 48 pt ring in the trailing vertical bar, in three positions.")
            }
        }
    }

    private func link(_ route: HoldRoute, symbol: String, colors: [Color], title: LocalizedStringKey, detail: LocalizedStringKey) -> some View {
        NavigationLink(value: route) {
            HStack(spacing: 14) {
                IconTile(symbol: symbol, colors: colors)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.dsHeadline).foregroundStyle(DS.ink)
                    Text(detail).font(.dsCaption).foregroundStyle(DS.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.ink3)
            }
            .card(padding: 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("hold.link.\(route.rawValue)")
    }
}

/// A tile in a style gallery: a live button and its name.
private struct GalleryCell<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 12) {
            content
                .frame(height: 84)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.ink2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(DS.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DS.line))
    }
}

/// The large live circle with a readout of what it's doing.
struct HoldHeroStage: View {
    @State private var readout = Text("Try it: press and hold the circle.")
    @State private var lastTrigger: SlideToConfirmTrigger?
    @State private var previous: SlideToConfirmState = .idle
    @State private var didHold = false

    var body: some View {
        VStack(spacing: 22) {
            HoldToConfirmButton(labels: .holdSend, systemImage: "paperplane.fill") { trigger in
                lastTrigger = trigger
                try await Task.sleep(for: .seconds(1.2))
            }
            .holdToConfirmConfiguration {
                $0.completionStyle = .morph
                $0.successBehavior = .reset(after: HeroStage.successResetDelay)
            }
            .onHoldToConfirmStateChange(updateReadout)
            .accessibilityIdentifier("hold.hero")

            readout
                .font(.system(size: 14))
                .foregroundStyle(DS.ink2)
                .multilineTextAlignment(.center)
                .frame(minHeight: 40)
                .accessibilityIdentifier("hold.readout")

            FlowLayout(spacing: 8, alignment: .center) {
                Chip(title: "Hold", detail: "1.2 s")
                Chip(title: "Lift early", detail: "drains back")
                Chip(title: "Slide off", detail: "cancels")
                Chip(title: "Tap", detail: "shows a hint")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 36)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                DS.surface
                RadialGradient(colors: [DS.accent.opacity(0.12), .clear], center: .center, startRadius: 0, endRadius: 220)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(DS.line, lineWidth: 1))
    }

    private func updateReadout(_ state: SlideToConfirmState) {
        defer { previous = state }
        let percent = Int((state.progress * 100).rounded())
        switch (state.phase, state.interaction) {
        case (.idle, .holding):
            didHold = true
            readout = Text("Holding").bold().foregroundStyle(DS.ink) + Text(" · \(percent)% · lift to cancel")
        case (.processing, _):
            readout = Text("Sending…").bold().foregroundStyle(DS.ink)
        case (.success, _):
            readout = Text("Sent").bold().foregroundStyle(DS.success)
                + Text(" \(lastTrigger.map(HoldHeroStage.describe) ?? ""). It resets in a moment.")
        case (.failure, _):
            readout = Text("Not sent").bold().foregroundStyle(DS.danger)
        case (.idle, .none):
            if lastTrigger != nil, previous.phase != .idle {
                lastTrigger = nil
                didHold = false
                readout = Text("Try it again: press and hold the circle.")
            } else if previous.interaction == .holding {
                readout = Text("Let go early at \(percent)%, so it drains back. Press again to pick up from where it is.")
            } else if previous.interaction == .pending, !didHold {
                readout = Text("That was a tap. Press and hold instead.")
            }
        default:
            break
        }
    }

    static func describe(_ trigger: SlideToConfirmTrigger) -> String {
        switch trigger {
        case .hold, .holdThenDrag, .drag: return "by holding"
        case .accessibility: return "with an assistive technology"
        case .keyboard: return "from the keyboard"
        }
    }
}

/// Display names for the hold styles.
enum HoldText {
    static func title(for style: HoldToConfirmProgressStyle) -> LocalizedStringKey {
        switch style {
        case .ring: return "Ring"
        case .segments: return "Segments"
        case .fill: return "Fill"
        case .liquid: return "Liquid"
        case .radial: return "Radial"
        case .pie: return "Pie"
        case .pulse: return "Pulse"
        case .glow: return "Glow"
        case .orbit: return "Orbit"
        case .countdown: return "Countdown"
        }
    }

    static func title(for style: HoldToConfirmCompletionStyle) -> LocalizedStringKey {
        switch style {
        case .checkmark: return "Check mark"
        case .ripple: return "Ripple"
        case .burst: return "Burst"
        case .bounce: return "Bounce"
        case .morph: return "Morph"
        case .flip: return "Flip"
        }
    }

    static func title(for position: HoldToConfirmLabelPosition) -> LocalizedStringKey {
        switch position {
        case .below: return "Below"
        case .above: return "Above"
        case .leading: return "Leading"
        case .trailing: return "Trailing"
        case .hidden: return "Hidden"
        }
    }

    static func title(for placement: HoldToConfirmPlacement) -> LocalizedStringKey {
        switch placement {
        case .bottomCenter: return "Bottom center"
        case .bottomCorner: return "Corner"
        case .thumbArc: return "Thumb arc"
        case .edge: return "Edge"
        }
    }

    static func title(for hand: ThumbReach.Hand) -> LocalizedStringKey {
        hand == .right ? "Right hand" : "Left hand"
    }

    static func title(for zone: ThumbReach.Zone) -> LocalizedStringKey {
        switch zone {
        case .natural: return "Natural"
        case .stretch: return "Stretch"
        case .hard: return "Hard"
        }
    }
}

extension SlideToConfirmLabels {
    /// Labels for a hold-only send button.
    static var holdSend: SlideToConfirmLabels {
        SlideToConfirmLabels(
            "Hold to send",
            holding: "Keep holding…",
            processing: "Sending…",
            success: "Sent",
            failure: "Not sent · try again"
        )
    }

    static var holdSendArabic: SlideToConfirmLabels {
        SlideToConfirmLabels(
            idle: Text(verbatim: "اضغط مطولاً للإرسال"),
            holding: Text(verbatim: "استمر بالضغط…"),
            processing: Text(verbatim: "جارٍ الإرسال…"),
            success: Text(verbatim: "تم الإرسال"),
            failure: Text(verbatim: "لم يُرسل · حاول مجدداً"),
            accessibilityHint: Text(verbatim: "اضغط مرتين للإرسال."),
            tapHint: Text(verbatim: "اضغط مطولاً")
        )
    }
}

/// A bare stage with the hero circle, used to record the README animation (`-screen record-hold`).
struct HoldRecordingStageView: View {
    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 18) {
                Eyebrow("HoldToConfirmButton")
                Text("Just a circle. Press and hold it.")
                    .font(.system(size: 30, weight: .bold))
                    .tracking(-0.8)
                    .foregroundStyle(DS.ink)
                HoldHeroStage()
            }
            .padding(.horizontal, DS.gutter)
            .padding(.vertical, 24)
            .frame(maxWidth: 560)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("record.stage")
        }
    }
}
