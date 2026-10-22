import SlideToConfirm
import SwiftUI

/// Every state of the control, frozen with `slideToConfirmPreviewState(_:)`, on light, dark and
/// brand surfaces.
struct StatesGalleryView: View {
    @Environment(AppModel.self) private var app
    @State private var surface: StageSurface?
    @State private var behavior: SlideToConfirmHoldBehavior = .combined

    private struct Row: Identifiable {
        let id: String
        let state: SlideToConfirmPreviewState
        let title: LocalizedStringKey
        let detail: LocalizedStringKey
    }

    private let rows: [Row] = [
        Row(id: "idle", state: .idle, title: "Idle", detail: "Shimmer runs toward the end. Drag the knob, or hold anywhere on the pill."),
        Row(id: "early", state: .holding(progress: 0.24), title: "Holding · early", detail: "After 180 ms the knob glides; the solid fill follows; the label rides ahead."),
        Row(id: "late", state: .holding(progress: 0.76), title: "Holding · late", detail: "The label hands over to white on the fill. The ring shows time left."),
        Row(id: "dragging", state: .dragging(progress: 0.46), title: "Dragging", detail: "A softer fill follows the finger; the label fades out of the way."),
        Row(id: "armed", state: .armed(progress: 0.94), title: "Armed", detail: "Past 90%: a haptic tick and “Release to send”."),
        Row(id: "processing", state: .processing, title: "Processing", detail: "Both paths land here. Locked until your action returns."),
        Row(id: "success", state: .success, title: "Success", detail: "Green only after success, with the success haptic."),
        Row(id: "failure", state: .failure(), title: "Failure", detail: "Shake, error haptic and a reason, then back to idle."),
        Row(id: "disabled", state: .disabled, title: "Disabled", detail: "Until the form is valid. Still announced to VoiceOver."),
    ]

    var body: some View {
        let surface = self.surface ?? app.initialSurface
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader(
                        eyebrow: "States",
                        title: "How it moves",
                        lead: "Holding uses the solid fill and a white label; dragging keeps the softer fill, so you can always tell which path you are on."
                    )
                    VStack(spacing: 10) {
                        Picker("Surface", selection: Binding(get: { surface }, set: { self.surface = $0 })) {
                            ForEach(StageSurface.allCases) { Text($0.title).tag($0) }
                        }
                        Picker("While holding", selection: $behavior) {
                            Text("Combined").tag(SlideToConfirmHoldBehavior.combined)
                            Text("Fill").tag(SlideToConfirmHoldBehavior.fill)
                            Text("Glide").tag(SlideToConfirmHoldBehavior.glide)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(spacing: 0) {
                        ForEach(rows) { row in
                            StateRow(title: row.title, detail: row.detail, surface: surface) {
                                control(row.state, surface: surface)
                            }
                            if row.id != rows.last?.id {
                                Divider().overlay(DS.line)
                            }
                        }
                    }
                    .card(padding: 0)

                    SectionHeader(eyebrow: "Directions", title: "Vertical tracks", lead: "Down suits a trailing vertical bar; up suits a door or a lift. Vertical tracks never mirror.")
                    HStack(spacing: 18) {
                        verticalSample(.down, state: .idle, caption: "Down · idle")
                        verticalSample(.down, state: .holding(progress: 0.62), caption: "Down · holding")
                        verticalSample(.up, state: .armed(), caption: "Up · armed")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(surface.color, in: RoundedRectangle(cornerRadius: DS.cornerRadius, style: .continuous))

                    SectionHeader(eyebrow: "Right to left", title: "Mirrors with the language", lead: "In Arabic the knob starts on the right and slides left. Text never mirrors.")
                    VStack(spacing: 14) {
                        control(.idle, surface: surface, arabic: true)
                        control(.holding(progress: 0.68), surface: surface, arabic: true)
                    }
                    .padding(20)
                    .background(surface.color, in: RoundedRectangle(cornerRadius: DS.cornerRadius, style: .continuous))

                    SectionHeader(eyebrow: "The circle", title: "HoldToConfirmButton", lead: "Same states, same engine. Frozen with holdToConfirmPreviewState(_:).")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 18) {
                        ForEach(Array(circleStates.enumerated()), id: \.offset) { _, item in
                            let (state, title) = item
                            VStack(spacing: 10) {
                                HoldToConfirmButton(labels: .holdSend, systemImage: "paperplane.fill") {}
                                    .holdToConfirmConfiguration(.compact.with {
                                        $0.labelPosition = .hidden
                                        $0.theme = surface == .brand ? .brand : .standard
                                    })
                                    .holdToConfirmPreviewState(state)
                                    .environment(\.colorScheme, surface.colorScheme)
                                Text(title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(surface.secondaryText)
                            }
                        }
                    }
                    .padding(.vertical, 22)
                    .padding(.horizontal, 12)
                    .background(surface.color, in: RoundedRectangle(cornerRadius: DS.cornerRadius, style: .continuous))
                }
                .padding(.horizontal, DS.gutter)
                .padding(.vertical, 12)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .background(DS.background.ignoresSafeArea())
            .navigationTitle("States")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { AppSettingsMenu() }
            }
        }
    }

    private let circleStates: [(HoldToConfirmPreviewState, LocalizedStringKey)] = [
        (.idle, "Idle"),
        (.holding(progress: 0.6), "Holding"),
        (.processing, "Processing"),
        (.success, "Success"),
        (.failure(), "Failure"),
        (.disabled, "Disabled"),
    ]

    private func control(_ state: SlideToConfirmPreviewState, surface: StageSurface, arabic: Bool = false) -> some View {
        SlideToConfirm(labels: arabic ? .sendMoneyArabic : .sendMoney) {}
            .slideToConfirmConfiguration {
                $0.holdBehavior = behavior
                $0.theme = surface == .brand ? .brand : .standard
            }
            .slideToConfirmPreviewState(state)
            .environment(\.colorScheme, surface.colorScheme)
            .environment(\.layoutDirection, arabic ? .rightToLeft : .leftToRight)
    }

    private func verticalSample(_ direction: SlideToConfirmDirection, state: SlideToConfirmPreviewState, caption: LocalizedStringKey) -> some View {
        let surface = self.surface ?? app.initialSurface
        return VStack(spacing: 10) {
            SlideToConfirm(labels: .sendMoney) {}
                .slideToConfirmConfiguration(.verticalBar.with {
                    $0.direction = direction
                    $0.holdBehavior = behavior
                    $0.theme = surface == .brand ? .brand : .standard
                })
                .slideToConfirmPreviewState(state)
                .environment(\.colorScheme, surface.colorScheme)
                .frame(height: 240)
            Text(caption)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(surface.secondaryText)
        }
    }
}

private struct StateRow<Control: View>: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let surface: StageSurface
    @ViewBuilder var control: Control

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(DS.ink)
                Text(detail).font(.system(size: 13)).foregroundStyle(DS.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            control
                .padding(.vertical, 18)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(surface.color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(16)
    }
}
