import SlideToConfirm
import SwiftUI

struct PlaygroundView: View {
    @State private var model = PlaygroundModel()
    @State private var readout = ""
    @State private var copied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                stage
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        codeCard
                        section("Surface") {
                            segmented(StageSurface.allCases, selection: $model.surface) { Text($0.title) }
                            segmented(DemoLanguage.allCases, selection: $model.language) { Text(verbatim: $0.title) }
                        }
                        section("Interaction") {
                            segmented(SlideToConfirmHoldBehavior.allCases, selection: $model.holdBehavior) { Text(Self.title(for: $0)) }
                            segmented(SlideToConfirmDirection.allCases, selection: $model.direction) { Text(Self.title(for: $0)) }
                            ToggleRow(title: "Knob can be dragged", isOn: $model.allowsDragging)
                            SliderRow(title: "Drag commits at", value: $model.commitThreshold, range: 0.6...0.98, step: 0.01) { "\(Int(($0 * 100).rounded()))%" }
                            SliderRow(title: "Hold duration", value: $model.holdDuration, range: 0.6...3, step: 0.1) { String(format: "%.1f s", $0) }
                            SliderRow(title: "Hold starts after", value: $model.holdDelay, range: 0.1...0.4, step: 0.02) { "\(Int(($0 * 1000).rounded())) ms" }
                        }
                        section("Size") {
                            SliderRow(title: "Container width", value: $model.containerWidth, range: 240...1100, step: 10) { "\(Int($0)) pt" }
                            SliderRow(title: "Max length", value: $model.maxLength, range: 260...640, step: 10) { "\(Int($0)) pt" }
                            SliderRow(title: "Thickness", value: $model.thickness, range: 44...80, step: 2) { "\(Int($0)) pt" }
                            SliderRow(title: "Knob inset", value: $model.knobInset, range: 2...8, step: 1) { "\(Int($0)) pt" }
                            SliderRow(title: "Label size", value: $model.labelSize, range: 13...19, step: 1) { "\(Int($0)) pt" }
                            ToggleRow(title: "Capsule", isOn: $model.isCapsule)
                            if !model.isCapsule {
                                SliderRow(title: "Corner radius", value: $model.cornerRadius, range: 0...30, step: 1) { "\(Int($0)) pt" }
                            }
                        }
                        section("Look") {
                            Picker("Theme", selection: $model.theme) {
                                ForEach(SlideToConfirmThemeChoice.allCases.filter { $0 != .brand }) { Text($0.title).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            .disabled(model.surface == .brand)
                            if model.theme == .custom && model.surface != .brand {
                                ColorPicker("Tint", selection: $model.customTint, supportsOpacity: false)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            ToggleRow(title: "Shimmer", isOn: $model.shimmer)
                            ToggleRow(title: "Hold ring", isOn: $model.showsHoldRing)
                            ToggleRow(title: "Haptics", isOn: $model.hapticsEnabled)
                        }
                        section("Outcome") {
                            ToggleRow(title: "Show processing for 1.3 s", isOn: $model.showsProcessing)
                            ToggleRow(title: "Simulate a failed action", isOn: $model.simulatesFailure)
                            ToggleRow(title: "Reset 2 s after success", isOn: $model.resetsAfterSuccess)
                        }
                        Button {
                            withAnimation(.smooth) { model.reset() }
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
            .navigationTitle("Playground")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { AppSettingsMenu() }
            }
        }
    }

    // MARK: Stage

    private var stage: some View {
        GeometryReader { proxy in
            let available = Double(proxy.size.width) - 24
            let container = min(model.containerWidth, available)
            let control = model.direction.isVertical ? model.thickness : min(model.maxLength, container - 40)
            VStack(spacing: 10) {
                Spacer(minLength: 0)
                SlideToConfirm(labels: model.language == .arabic ? .sendMoneyArabic : .sendMoney) {
                    if model.showsProcessing { try await Task.sleep(for: .seconds(1.3)) }
                    if model.simulatesFailure { throw SimulatedFailure() }
                }
                .slideToConfirmConfiguration(model.configuration)
                .slideToConfirmHaptics(model.hapticsEnabled ? .automatic : .disabled)
                .onSlideToConfirmStateChange { state in
                    readout = describe(state)
                }
                .frame(height: model.direction.isVertical ? 240 : nil)
                .padding(.horizontal, 20)
                .frame(width: container)
                .overlay {
                    HStack {
                        guide
                        Spacer()
                        guide
                    }
                    .padding(.vertical, -12)
                }
                .environment(\.colorScheme, model.surface.colorScheme)
                .demoLanguage(model.language)
                .accessibilityIdentifier("playground.control")
                Text(verbatim: "container \(Int(container - 40)) pt · control \(Int(control)) pt\(container - 40 > model.maxLength && !model.direction.isVertical ? " · capped" : "")")
                    .font(.dsMono)
                    .foregroundStyle(model.surface.secondaryText)
                Text(verbatim: readout.isEmpty ? " " : readout)
                    .font(.system(size: 13))
                    .foregroundStyle(model.surface.secondaryText)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(model.surface.color, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(DS.line))
        }
        .frame(height: model.direction.isVertical ? 360 : 210)
        .animation(.smooth(duration: 0.3), value: model.direction)
        .animation(.smooth(duration: 0.25), value: model.surface)
    }

    private var guide: some View {
        Rectangle()
            .fill(.clear)
            .frame(width: 1)
            .overlay(
                Rectangle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .foregroundStyle(Color(hex: 0x7F89A6).opacity(0.6))
            )
    }

    private func describe(_ state: SlideToConfirmState) -> String {
        let percent = Int((state.progress * 100).rounded())
        switch (state.phase, state.interaction) {
        case (.idle, .holding): return "Holding · \(percent)%"
        case (.idle, .dragging): return state.isArmed ? "Armed · release to confirm" : "Dragging · \(percent)%"
        case (.idle, .pending): return "Touch down…"
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
                Text(verbatim: "Configuration.swift")
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
                .accessibilityIdentifier("playground.copy")
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

    private func segmented<Value: Hashable & Identifiable, Label: View>(
        _ values: [Value],
        selection: Binding<Value>,
        @ViewBuilder label: @escaping (Value) -> Label
    ) -> some View {
        Picker("", selection: selection) {
            ForEach(values) { label($0).tag($0) }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    static func title(for behavior: SlideToConfirmHoldBehavior) -> LocalizedStringKey {
        switch behavior {
        case .combined: return "Combined"
        case .fill: return "Fill"
        case .glide: return "Glide"
        case .none: return "Off"
        }
    }

    static func title(for direction: SlideToConfirmDirection) -> LocalizedStringKey {
        switch direction {
        case .trailing: return "Trailing"
        case .down: return "Down"
        case .up: return "Up"
        }
    }
}

private struct SimulatedFailure: Error {}

struct SliderRow: View {
    let title: LocalizedStringKey
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(DS.ink)
                Spacer()
                Text(verbatim: format(value)).font(.dsMono).foregroundStyle(DS.ink2).monospacedDigit()
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

struct ToggleRow: View {
    let title: LocalizedStringKey
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(DS.ink)
        }
    }
}

/// Lightweight Swift syntax coloring for the generated snippet.
struct SwiftCodeText: View {
    let code: String

    private static let keywords: Set<String> = ["try", "await", "let", "var", "func", "true", "false", "nil", "in", "throw"]

    var body: some View {
        Text(highlighted)
            .font(.system(size: 12.5, design: .monospaced))
            .lineSpacing(3)
            .textSelection(.enabled)
            .fixedSize()
    }

    private var highlighted: AttributedString {
        var result = AttributedString()
        var token = ""
        var inString = false

        func flush() {
            guard !token.isEmpty else { return }
            var piece = AttributedString(token)
            if inString {
                piece.foregroundColor = Color(hex: 0xFFC66D)
            } else if Self.keywords.contains(token) {
                piece.foregroundColor = Color(hex: 0xFF8CC6)
            } else if token.first?.isUppercase == true {
                piece.foregroundColor = Color(hex: 0x7FD8FF)
            } else if token.first?.isNumber == true {
                piece.foregroundColor = Color(hex: 0xC7A6FF)
            } else {
                piece.foregroundColor = Color(hex: 0xE3E7F2)
            }
            result += piece
            token = ""
        }

        for character in code {
            if character == "\"" {
                if inString {
                    token.append(character)
                    flush()
                    inString = false
                } else {
                    flush()
                    inString = true
                    token.append(character)
                }
            } else if inString || character.isLetter || character.isNumber || character == "_" || (character == "." && token.first?.isNumber == true) {
                token.append(character)
            } else {
                flush()
                var piece = AttributedString(String(character))
                piece.foregroundColor = Color(hex: 0xA3AABF)
                result += piece
            }
        }
        flush()
        return result
    }
}
