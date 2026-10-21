import SlideToConfirm
import SwiftUI

struct ShowcaseView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 36) {
                    header
                    HeroStage()
                    steps
                    compare
                    footer
                }
                .padding(.horizontal, DS.gutter)
                .padding(.top, 8)
                .padding(.bottom, 40)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .background(DS.background.ignoresSafeArea())
            .navigationTitle("Showcase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { AppSettingsMenu() }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("Slide + hold, combined")
            Text("One pill. Slide it, or just hold it.")
                .font(.dsDisplay)
                .tracking(-1)
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Drag the knob to the end, or press and hold anywhere on the pill. While you hold, the knob glides to the end by itself and the pill fills in behind it. Let go early and it springs back.")
                .font(.dsLead)
                .foregroundStyle(DS.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(eyebrow: "How it works", title: "Two gestures, one ending")
            VStack(spacing: 0) {
                StepRow(number: 1, title: "Touch down", detail: "For 180 ms nothing moves. A 6 pt move along the track on the knob means drag. A still finger means hold.")
                Divider().overlay(DS.line)
                StepRow(number: 2, title: "Hold glides the knob", detail: "The knob travels at a steady pace and the pill fills solid behind it. The label rides ahead, then hands over to a white label on the fill.")
                Divider().overlay(DS.line)
                StepRow(number: 3, title: "Take over any time", detail: "Move more than 12 pt on the knob while holding and you drag it from where it is. Lift early and it springs back.")
                Divider().overlay(DS.line)
                StepRow(number: 4, title: "Same ending", detail: "Commit at the end of the hold or past 90% of a drag. A haptic tick, processing, then success only after your action returns.")
            }
            .card(padding: 0)
        }
    }

    private var compare: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                eyebrow: "Compare",
                title: "Combined, Fill or Glide",
                lead: "All three share the drag path. They differ only in what moves while you hold. Press and hold each one."
            )
            BehaviorCard(
                behavior: .combined,
                title: "Combined",
                badge: Badge(text: "Recommended"),
                summary: "The knob glides and the pill fills behind it. One progress value drives both.",
                bullets: [
                    ("One picture of progress.", "Knob and fill always agree, whether you drag or hold."),
                    ("Easy take-over.", "The knob is already where your thumb expects it."),
                    ("Clear ending.", "The fill reaches the end exactly when it commits."),
                ]
            )
            BehaviorCard(
                behavior: .fill,
                title: "Fill",
                badge: Badge(text: "Calm", style: .soft),
                summary: "The knob stays put. The pill fills from the start edge and the label turns white as the fill passes.",
                bullets: [
                    ("Least motion.", "Suits dense screens."),
                    ("Two progress values.", "A drag after a partial fill starts from zero."),
                    ("Drains back", "at three times the fill speed on early release."),
                ]
            )
            BehaviorCard(
                behavior: .glide,
                title: "Glide",
                badge: Badge(text: "Automatic", style: .soft),
                summary: "The knob slides by itself with the soft drag fill. No solid fill.",
                bullets: [
                    ("Feels like an auto-slide.", "Same look as dragging."),
                    ("Weaker countdown.", "Only the ring shows time left."),
                    ("Label hides", "behind the knob after halfway."),
                ]
            )
        }
    }

    private var footer: some View {
        Text("Names and amounts are placeholders. Every control on this screen is the same `SlideToConfirm` view with a different configuration.")
            .font(.dsCaption)
            .foregroundStyle(DS.ink3)
    }
}

/// The large live control with a readout of what it's doing.
struct HeroStage: View {
    @State private var readout: Text = Text("Try it: drag the knob, or press and hold anywhere on the pill.")
    @State private var lastTrigger: SlideToConfirmTrigger?
    @State private var wasInteracting = false

    var body: some View {
        VStack(spacing: 22) {
            SlideToConfirm(labels: .sendMoney) { trigger in
                lastTrigger = trigger
                try await Task.sleep(for: .seconds(1.3))
            }
            .slideToConfirmConfiguration { $0.successBehavior = .reset(after: 2.2) }
            .onSlideToConfirmStateChange(updateReadout)
            .accessibilityIdentifier("hero.control")

            readout
                .font(.system(size: 14))
                .foregroundStyle(DS.ink2)
                .multilineTextAlignment(.center)
                .frame(minHeight: 40)
                .contentTransition(.numericText())
                .accessibilityIdentifier("hero.readout")

            FlowLayout(spacing: 8, alignment: .center) {
                Chip(title: "Drag", detail: "release past 90%")
                Chip(title: "Hold", detail: "1.2 s, anywhere")
                Chip(title: "Lift early", detail: "springs back")
                Chip(title: "VoiceOver", detail: "double-tap")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 44)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                DS.surface
                RadialGradient(colors: [DS.accent.opacity(0.10), .clear], center: .top, startRadius: 0, endRadius: 320)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(DS.line, lineWidth: 1))
    }

    private func updateReadout(_ state: SlideToConfirmState) {
        let percent = Int((state.progress * 100).rounded())
        switch (state.phase, state.interaction) {
        case (.idle, .holding):
            wasInteracting = true
            readout = Text("Holding").bold().foregroundStyle(DS.ink) + Text(" · \(percent)% · lift to cancel")
        case (.idle, .dragging):
            wasInteracting = true
            readout = state.isArmed
                ? Text("Armed").bold().foregroundStyle(DS.ink) + Text(" · release to send")
                : Text("Dragging").bold().foregroundStyle(DS.ink) + Text(" · \(percent)% · commits at 90%")
        case (.processing, _):
            wasInteracting = false
            readout = Text("Sending…").bold().foregroundStyle(DS.ink)
        case (.success, _):
            readout = Text("Sent").bold().foregroundStyle(DS.success)
                + Text(" \(lastTrigger.map(Self.describe) ?? ""). It resets in a moment.")
        case (.idle, .none):
            if lastTrigger != nil {
                lastTrigger = nil
                readout = Text("Try it again: drag the knob, or press and hold anywhere on the pill.")
            } else if wasInteracting {
                wasInteracting = false
                readout = Text("Released early, so it sprang back. Hold to the end, or drag past 90%.")
            }
        default:
            break
        }
    }

    static func describe(_ trigger: SlideToConfirmTrigger) -> String {
        switch trigger {
        case .drag: return "by dragging"
        case .hold: return "by holding"
        case .holdThenDrag: return "by holding, then dragging"
        case .accessibility: return "with an assistive technology"
        case .keyboard: return "from the keyboard"
        }
    }
}

private struct StepRow: View {
    let number: Int
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(DS.accentInk)
                .frame(width: 28, height: 28)
                .background(DS.accentSoft, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(DS.ink)
                Text(detail).font(.system(size: 14)).foregroundStyle(DS.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}

private struct BehaviorCard: View {
    let behavior: SlideToConfirmHoldBehavior
    let title: LocalizedStringKey
    let badge: Badge
    let summary: LocalizedStringKey
    let bullets: [(LocalizedStringKey, LocalizedStringKey)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title).font(.dsHeadline).foregroundStyle(DS.ink)
                Spacer()
                badge
            }
            Text(summary)
                .font(.dsCaption)
                .foregroundStyle(DS.ink2)
                .fixedSize(horizontal: false, vertical: true)
            SlideToConfirm(labels: .sendMoney) {
                try await Task.sleep(for: .seconds(1))
            }
            .slideToConfirmConfiguration {
                $0.holdBehavior = behavior
                $0.successBehavior = .reset(after: 1.8)
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(DS.surfaceRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(DS.line, lineWidth: 1))
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(bullets.enumerated()), id: \.offset) { _, bullet in
                    Bullet(title: bullet.0, detail: bullet.1)
                }
            }
        }
        .card()
        .overlay(
            RoundedRectangle(cornerRadius: DS.cornerRadius, style: .continuous)
                .strokeBorder(behavior == .combined ? DS.accent : .clear, lineWidth: 2)
        )
    }
}

extension SlideToConfirmLabels {
    /// The labels from the design: sending money.
    static var sendMoney: SlideToConfirmLabels {
        SlideToConfirmLabels(
            "Slide or hold to send",
            armed: "Release to send",
            holding: "Keep holding…",
            processing: "Sending…",
            success: "Sent",
            failure: "Not sent · try again"
        )
    }

    static var sendMoneyArabic: SlideToConfirmLabels {
        SlideToConfirmLabels(
            idle: Text(verbatim: "اسحب أو اضغط مطولاً للإرسال"),
            armed: Text(verbatim: "اترك للإرسال"),
            holding: Text(verbatim: "استمر بالضغط…"),
            processing: Text(verbatim: "جارٍ الإرسال…"),
            success: Text(verbatim: "تم الإرسال"),
            failure: Text(verbatim: "لم يُرسل · حاول مجدداً"),
            accessibilityHint: Text(verbatim: "اضغط مرتين للإرسال.")
        )
    }
}
