import Observation
import SlideToConfirm
import SwiftUI

/// Every option of the circle, live, with the code that produces it.
struct HoldComposerView: View {
    @State private var model = HoldComposerModel()
    @State private var readout = ""
    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            stage
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    codeCard
                    section("While holding") {
                        chips(HoldToConfirmProgressStyle.allCases, selection: $model.progressStyle, id: "progress") { HoldText.title(for: $0) }
                        SliderRow(title: "Hold duration", value: $model.holdDuration, range: 0.6...3, step: 0.1) { String(format: "%.1f s", $0) }
                        Picker("", selection: $model.releaseBehavior) {
                            Text("Drains on release").tag(HoldToConfirmReleaseBehavior.drain)
                            Text("Resets on release").tag(HoldToConfirmReleaseBehavior.reset)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        ToggleRow(title: "Hint on tap", isOn: $model.hintsOnTap)
                    }
                    section("When it's done") {
                        chips(HoldToConfirmCompletionStyle.allCases, selection: $model.completionStyle, id: "completion") { HoldText.title(for: $0) }
                        ToggleRow(title: "Simulate a failed action", isOn: $model.simulatesFailure)
                        ToggleRow(title: "Reset 2 s after success", isOn: $model.resetsAfterSuccess)
                    }
                    section("Size and label") {
                        Picker("", selection: $model.size) {
                            ForEach(HoldComposerModel.Size.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        Picker("", selection: $model.labelPosition) {
                            ForEach(HoldToConfirmLabelPosition.allCases) { Text(HoldText.title(for: $0)).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    section("Look") {
                        Picker("", selection: $model.surface) {
                            ForEach(StageSurface.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        Picker("Theme", selection: $model.theme) {
                            ForEach(SlideToConfirmThemeChoice.allCases.filter { $0 != .brand && $0 != .custom }) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .disabled(model.surface == .brand)
                        ToggleRow(title: "Haptics", isOn: $model.hapticsEnabled)
                    }
                    Button {
                        withAnimation(.smooth) { model = HoldComposerModel() }
                    } label: {
                        Label("Reset to defaults", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.horizontal, DS.gutter)
                .padding(.bottom, 32)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
        }
        .background(DS.background.ignoresSafeArea())
        .navigationTitle("Composer")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Stage

    private var stage: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 0)
            HoldToConfirmButton(labels: .holdSend, systemImage: "paperplane.fill") {
                try await Task.sleep(for: .seconds(1.2))
                if model.simulatesFailure { throw SlideToConfirmFailure("Not sent · declined") }
            }
            .holdToConfirmConfiguration(model.configuration)
            .slideToConfirmHaptics(model.hapticsEnabled ? .automatic : .disabled)
            .onHoldToConfirmStateChange { readout = describe($0) }
            .environment(\.colorScheme, model.surface.colorScheme)
            .accessibilityIdentifier("composer.control")
            .id(model.size)
            Text(verbatim: readout.isEmpty ? " " : readout)
                .font(.system(size: 13))
                .foregroundStyle(model.surface.secondaryText)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .background(model.surface.color, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(DS.line))
        .animation(.smooth(duration: 0.25), value: model.surface)
    }

    private func describe(_ state: SlideToConfirmState) -> String {
        let percent = Int((state.progress * 100).rounded())
        switch (state.phase, state.interaction) {
        case (.idle, .holding): return "Holding · \(percent)%"
        case (.idle, .pending): return "Touch down…"
        case (.idle, .none) where state.progress > 0: return "Draining · \(percent)%"
        case (.processing, _): return "Processing…"
        case (.success, _): return "Confirmed"
        case (.failure, _): return "Failed · shake, error haptic, back to idle"
        default: return ""
        }
    }

    // MARK: Code

    private var codeCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(verbatim: "HoldButton.swift")
                    .font(.dsMono)
                    .foregroundStyle(Color(hex: 0x7F89A6))
                Spacer()
                Button {
                    UIPasteboard.general.string = model.code
                    copied = true
                    Task {
                        try? await Task.sleep(for: .seconds(1.4))
                        copied = false
                    }
                } label: {
                    Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: 0xE3E7F2))
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 10)
            .padding(.vertical, 8)
            Divider().overlay(Color.white.opacity(0.06))
            ScrollView(.horizontal, showsIndicators: false) {
                SwiftCodeText(code: model.code)
                    .padding(16)
            }
        }
        .background(DS.codeBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: Helpers

    private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(title, color: DS.ink3)
            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .card(padding: 16)
        }
    }

    private func chips<Value: Hashable & Identifiable & RawRepresentable>(
        _ values: [Value],
        selection: Binding<Value>,
        id: String,
        title: @escaping (Value) -> LocalizedStringKey
    ) -> some View where Value.RawValue == String {
        FlowLayout(spacing: 8) {
            ForEach(values) { value in
                let isSelected = selection.wrappedValue == value
                Button {
                    selection.wrappedValue = value
                } label: {
                    Text(title(value))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.white : DS.ink)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(isSelected ? DS.accent : DS.surfaceRaised, in: Capsule())
                        .overlay(Capsule().strokeBorder(isSelected ? .clear : DS.line))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("composer.\(id).\(value.rawValue)")
            }
        }
    }
}

/// The composer's settings, and the configuration and code they produce.
@Observable
final class HoldComposerModel {
    enum Size: String, CaseIterable, Identifiable {
        case compact, standard, large

        var id: String { rawValue }

        var title: LocalizedStringKey {
            switch self {
            case .compact: return "Compact"
            case .standard: return "Default"
            case .large: return "Large"
            }
        }

        var preset: HoldToConfirmConfiguration {
            switch self {
            case .compact: return .compact
            case .standard: return .default
            case .large: return .large
            }
        }
    }

    var progressStyle: HoldToConfirmProgressStyle = .ring
    var completionStyle: HoldToConfirmCompletionStyle = .checkmark
    var releaseBehavior: HoldToConfirmReleaseBehavior = .drain
    var holdDuration: Double = 1.2
    var hintsOnTap = true
    var simulatesFailure = false
    var resetsAfterSuccess = true
    var size: Size = .standard
    var labelPosition: HoldToConfirmLabelPosition = .below
    var surface: StageSurface = .light
    var theme: SlideToConfirmThemeChoice = .standard
    var hapticsEnabled = true

    var resolvedTheme: SlideToConfirmTheme {
        if surface == .brand { return .brand }
        switch theme {
        case .standard, .brand, .custom: return .standard
        case .destructive: return .destructive
        case .positive: return .positive
        case .monochrome: return .monochrome
        }
    }

    var configuration: HoldToConfirmConfiguration {
        size.preset.with {
            $0.progressStyle = progressStyle
            $0.completionStyle = completionStyle
            $0.releaseBehavior = releaseBehavior
            $0.holdDuration = holdDuration
            $0.hintsOnTap = hintsOnTap
            $0.labelPosition = labelPosition
            $0.theme = resolvedTheme
            $0.successBehavior = resetsAfterSuccess ? .reset(after: 2) : .remain
        }
    }

    /// The SwiftUI code for the current settings, listing only what differs from the preset.
    var code: String {
        let base = size.preset
        var lines: [String] = []
        if progressStyle != base.progressStyle { lines.append("$0.progressStyle = .\(progressStyle.rawValue)") }
        if completionStyle != base.completionStyle { lines.append("$0.completionStyle = .\(completionStyle.rawValue)") }
        if releaseBehavior != base.releaseBehavior { lines.append("$0.releaseBehavior = .\(releaseBehavior.rawValue)") }
        if abs(holdDuration - base.holdDuration) > 0.01 { lines.append(String(format: "$0.holdDuration = %.1f", holdDuration)) }
        if hintsOnTap != base.hintsOnTap { lines.append("$0.hintsOnTap = \(hintsOnTap)") }
        if labelPosition != base.labelPosition { lines.append("$0.labelPosition = .\(labelPosition.rawValue)") }
        if surface == .brand {
            lines.append("$0.theme = .brand")
        } else if theme != .standard && theme != .custom {
            lines.append("$0.theme = .\(theme.rawValue)")
        }
        if resetsAfterSuccess { lines.append("$0.successBehavior = .reset(after: 2)") }

        var code = """
        HoldToConfirmButton("Hold to send", systemImage: "paperplane.fill") {
            try await transfer.send()
        }
        """
        let preset = size == .standard ? nil : ".\(size.rawValue)"
        if !lines.isEmpty {
            let body = lines.map { "    \($0)" }.joined(separator: "\n")
            if let preset {
                code += "\n.holdToConfirmConfiguration(\(preset).with {\n\(body)\n})"
            } else {
                code += "\n.holdToConfirmConfiguration {\n\(body)\n}"
            }
        } else if let preset {
            code += "\n.holdToConfirmConfiguration(\(preset))"
        }
        if !hapticsEnabled { code += "\n.slideToConfirmHaptics(.disabled)" }
        return code
    }
}
