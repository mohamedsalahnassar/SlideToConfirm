import SlideToConfirm
import SwiftUI

/// A checkout screen with a floating circle, over a heat map of where the thumb reaches.
/// Launch with `-screen hold-reach -hand left -placement edge` to preselect.
struct ReachMapView: View {
    enum Kind: String, CaseIterable, Identifiable {
        case bottomCenter, bottomCorner, thumbArc, edge

        var id: String { rawValue }

        func placement(for hand: ThumbReach.Hand) -> HoldToConfirmPlacement {
            switch self {
            case .bottomCenter: return .bottomCenter
            case .bottomCorner: return .bottomCorner(hand)
            case .thumbArc: return .thumbArc(hand)
            case .edge: return .edge(hand)
            }
        }
    }

    @Environment(AppModel.self) private var model
    @State private var hand = UserDefaults.standard.string(forKey: "hand").flatMap(ThumbReach.Hand.init(rawValue:)) ?? .right
    @State private var kind = UserDefaults.standard.string(forKey: "placement").flatMap(Kind.init(rawValue:)) ?? .thumbArc
    @State private var showsHeatMap = true
    @State private var screenSize: CGSize = .zero
    @State private var buttonFrame: CGRect = .zero

    private let configuration = HoldToConfirmConfiguration.default.with {
        $0.successBehavior = .reset(after: 1.6)
        $0.completionStyle = .ripple
    }

    var body: some View {
        ZStack {
            content
            if showsHeatMap {
                ThumbReachOverlay(hand: hand, opacity: 0.26)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .holdToConfirmOverlay(kind.placement(for: hand)) {
            HoldToConfirmButton(labels: model.language == .arabic ? .holdPayArabic : .holdPay, systemImage: "creditcard.fill") {
                try await Task.sleep(for: .seconds(1))
            }
            .holdToConfirmConfiguration(configuration)
            .demoLanguage(model.language)
            .background(GeometryReader { proxy in
                Color.clear.preference(key: ButtonFrameKey.self, value: proxy.frame(in: .global))
            })
            .accessibilityIdentifier("reach.control")
        }
        .onPreferenceChange(ButtonFrameKey.self) { buttonFrame = $0 }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { screenSize = proxy.size }
                    .onChange(of: proxy.size) { _, size in screenSize = size }
            }
            .ignoresSafeArea()
        }
        .background(DS.background.ignoresSafeArea())
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: kind)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: hand)
        .animation(.easeInOut(duration: 0.2), value: showsHeatMap)
        .navigationTitle("Thumb reach")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Toggle(isOn: $showsHeatMap) {
                    Image(systemName: "flame")
                }
                .toggleStyle(.button)
                .accessibilityLabel("Heat map")
                .accessibilityIdentifier("reach.heatmap")
            }
        }
    }

    // MARK: Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            controls
            verdict
            receipt
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DS.gutter)
        .padding(.top, 8)
        .frame(maxWidth: 560, maxHeight: .infinity, alignment: .top)
        .frame(maxWidth: .infinity)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Hand", selection: $hand) {
                ForEach(ThumbReach.Hand.allCases) { Text(HoldText.title(for: $0)).tag($0) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("reach.hand")
            Picker("Placement", selection: $kind) {
                ForEach(Kind.allCases) { kind in
                    Text(HoldText.title(for: kind.placement(for: hand))).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("reach.placement")
        }
        .card(padding: 12)
    }

    @ViewBuilder
    private var verdict: some View {
        let current = zone(for: hand)
        let other = zone(for: hand.opposite)
        let thumb: Text = hand == .right ? Text("right thumb") : Text("left thumb")
        let otherThumb: Text = hand == .right ? Text("for the left thumb.") : Text("for the right thumb.")
        let headline: Text = Text(HoldText.title(for: current)).bold() + Text(verbatim: " · ") + thumb
        let detail: Text = Text(HoldText.title(for: other)) + Text(verbatim: " ") + otherThumb
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(color(for: current))
                .frame(width: 10, height: 10)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 2) {
                headline
                    .font(.system(size: 14))
                    .foregroundStyle(DS.ink)
                (detail + Text(verbatim: " ") + Text(advice(zone: current, other: other)))
                    .font(.system(size: 13))
                    .foregroundStyle(DS.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("reach.verdict")
    }

    private var receipt: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                IconTile(symbol: "cup.and.saucer.fill", colors: [Color(hex: 0xFFB547), Color(hex: 0xF07F13)], size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bloom Café").font(.system(size: 15, weight: .semibold)).foregroundStyle(DS.ink)
                    Text("Table 4 · 2 items").font(.system(size: 13)).foregroundStyle(DS.ink2)
                }
                Spacer(minLength: 0)
                Text(verbatim: "AED 46.50")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.ink)
                    .environment(\.layoutDirection, .leftToRight)
            }
            .padding(.vertical, 12)
            Divider().overlay(DS.line)
            DetailRow(title: Text("Flat white × 2"), value: Text(verbatim: "AED 38.00").environment(\.layoutDirection, .leftToRight))
            Divider().overlay(DS.line)
            DetailRow(title: Text("Almond croissant"), value: Text(verbatim: "AED 8.50").environment(\.layoutDirection, .leftToRight))
        }
        .padding(.horizontal, 16)
        .card(padding: 0)
    }

    // MARK: Reach

    private func zone(for hand: ThumbReach.Hand) -> ThumbReach.Zone {
        guard screenSize != .zero, buttonFrame != .zero else { return .natural }
        let center = CGPoint(x: buttonFrame.midX, y: buttonFrame.minY + configuration.outerDiameter / 2)
        return ThumbReach.zone(at: center, in: screenSize, hand: hand)
    }

    private func color(for zone: ThumbReach.Zone) -> Color {
        switch zone {
        case .natural: return .green
        case .stretch: return .yellow
        case .hard: return .red
        }
    }

    private func advice(zone: ThumbReach.Zone, other: ThumbReach.Zone) -> LocalizedStringKey {
        if zone == .natural && other == .natural { return "Safe for either hand." }
        if zone == .natural { return "Mirror it when someone switches hands." }
        return "Too far to hold comfortably. Move it lower."
    }
}

private struct ButtonFrameKey: PreferenceKey {
    static var defaultValue: CGRect { .zero }
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

extension SlideToConfirmLabels {
    static var holdPay: SlideToConfirmLabels {
        SlideToConfirmLabels("Hold to pay", holding: "Keep holding…", processing: "Paying…", success: "Paid")
    }

    static var holdPayArabic: SlideToConfirmLabels {
        SlideToConfirmLabels(
            idle: Text(verbatim: "اضغط مطولاً للدفع"),
            holding: Text(verbatim: "استمر بالضغط…"),
            processing: Text(verbatim: "جارٍ الدفع…"),
            success: Text(verbatim: "تم الدفع"),
            tapHint: Text(verbatim: "اضغط مطولاً")
        )
    }
}
