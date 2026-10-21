import SlideToConfirm
import SwiftUI

// MARK: - Unlock

/// Slide only, with a lock knob that opens on success and a glow that tracks progress.
struct UnlockScenario: View {
    @State private var state = SlideToConfirmState.idle

    var body: some View {
        let progress = state.phase == .idle ? state.progress : 1
        let isOpen = state.phase == .success
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                Circle()
                    .fill(DS.surface)
                    .frame(width: 220, height: 220)
                    .shadow(color: .black.opacity(0.06), radius: 20, y: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isOpen ? DS.success : Color(hex: 0x16884A),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 240, height: 240)
                Image(systemName: isOpen ? "lock.open.fill" : "lock.fill")
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundStyle(isOpen ? DS.success : DS.ink)
                    .contentTransition(.symbolEffect(.replace))
            }
            .animation(.smooth, value: isOpen)
            VStack(spacing: 6) {
                Text(isOpen ? "Front door unlocked" : "Front door")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(DS.ink)
                    .contentTransition(.opacity)
                Text(isOpen ? "Locks again in a moment" : "Locked · Home")
                    .font(.dsBody)
                    .foregroundStyle(DS.ink2)
            }
            .padding(.top, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(DS.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            BottomConfirmBar {
                SlideToConfirm(labels: SlideToConfirmLabels(
                    "Slide to unlock",
                    armed: "Release to unlock",
                    processing: "Unlocking…",
                    success: "Unlocked"
                )) {
                    try await Task.sleep(for: .seconds(0.8))
                }
                .slideToConfirmConfiguration(.slideOnly.with {
                    $0.theme = .positive
                    $0.icons = SlideToConfirmIcons(idle: .systemImage("lock.fill"), success: .systemImage("lock.open.fill"))
                    $0.successBehavior = .reset(after: 2.5)
                })
                .onSlideToConfirmStateChange { state = $0 }
                .accessibilityIdentifier("unlock.control")
            }
        }
        .navigationTitle("Unlock")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Checkout on a brand surface

/// A translucent track and white knob on a colored background, with a custom card knob.
struct CheckoutScenario: View {
    private let brand = Color(hex: 0x4F46E5)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x7C3AED), Color(hex: 0x4F46E5), Color(hex: 0x1E1B6B)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 420)
                .offset(x: 160, y: -260)
                .blur(radius: 2)

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Order #1042").font(.system(size: 15, weight: .medium)).foregroundStyle(.white.opacity(0.7))
                    Text("$129.00").font(.system(size: 48, weight: .bold)).foregroundStyle(.white).monospacedDigit()
                }
                VStack(spacing: 0) {
                    lineItem("Wireless headphones", "$109.00")
                    lineItem("Express delivery", "$12.00")
                    lineItem("Tax", "$8.00")
                }
                .padding(.horizontal, 16)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.18)))

                HStack(spacing: 12) {
                    Image(systemName: "creditcard.fill").font(.system(size: 18)).foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.14), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Visa ··4242").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                        Text("Billing address on file").font(.system(size: 13)).foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                }

                Spacer()

                SlideToConfirm(labels: SlideToConfirmLabels(
                    "Slide or hold to pay $129.00",
                    armed: "Release to pay",
                    holding: "Keep holding…",
                    processing: "Paying…",
                    success: "Paid"
                )) {
                    try await Task.sleep(for: .seconds(1.4))
                }
                .slideToConfirmTheme(.onColor(brand))
                .slideToConfirmConfiguration { $0.successBehavior = .reset(after: 2.5) }
                .slideToConfirmKnob { knob in
                    Image(systemName: knob.state.phase == .success ? "checkmark" : "creditcard.fill")
                        .font(.system(size: knob.diameter * 0.36, weight: .bold))
                        .foregroundStyle(knob.iconColor)
                        .contentTransition(.symbolEffect(.replace))
                }
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("checkout.control")

                Text("Payments are simulated.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
            }
            .padding(DS.gutter)
            .frame(maxWidth: 560)
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .environment(\.colorScheme, .dark)
    }

    private func lineItem(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.white.opacity(0.8))
            Spacer()
            Text(value).fontWeight(.semibold).foregroundStyle(.white).monospacedDigit()
        }
        .font(.system(size: 15))
        .frame(minHeight: 46)
    }
}

// MARK: - Delete account

/// Destructive theme, a calm 2-second fill hold and an accessibility alert as a second step.
struct DeleteAccountScenario: View {
    @State private var isDeleted = false
    @State private var attempt = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if isDeleted {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(DS.success)
                            .symbolEffect(.bounce, value: isDeleted)
                        Text("Account scheduled for deletion").font(.system(size: 20, weight: .bold)).foregroundStyle(DS.ink)
                        Text("You have 30 days to change your mind.").font(.dsBody).foregroundStyle(DS.ink2)
                        Button("Restore account") {
                            attempt += 1
                            withAnimation(.smooth) { isDeleted = false }
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 6)
                    }
                    .frame(maxWidth: .infinity)
                    .card(padding: 28)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                } else {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(DS.danger)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("This can't be undone after 30 days").font(.system(size: 16, weight: .semibold)).foregroundStyle(DS.ink)
                            Text("Deleting your account removes everything below for good.").font(.dsCaption).foregroundStyle(DS.ink2)
                        }
                    }
                    .card(padding: 16, background: DS.dangerSoft)

                    VStack(spacing: 0) {
                        removal("photo.on.rectangle", "2,481 photos and videos")
                        Divider().overlay(DS.line)
                        removal("bubble.left.and.bubble.right", "Messages and shared albums")
                        Divider().overlay(DS.line)
                        removal("creditcard", "Saved cards and subscriptions")
                        Divider().overlay(DS.line)
                        removal("person.2", "Family sharing")
                    }
                    .padding(.horizontal, 16)
                    .card(padding: 0)
                }
            }
            .padding(DS.gutter)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(DS.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if !isDeleted {
                BottomConfirmBar {
                    SlideToConfirm(labels: SlideToConfirmLabels(
                        "Hold to delete account",
                        armed: "Release to delete",
                        holding: "Keep holding to delete…",
                        processing: "Deleting…",
                        success: "Deleted"
                    )) {
                        try await Task.sleep(for: .seconds(1.2))
                    }
                    .slideToConfirmConfiguration {
                        $0.theme = .destructive
                        $0.holdBehavior = .fill
                        $0.holdDuration = 2
                        $0.icons.idle = .systemImage("trash.fill")
                    }
                    .slideToConfirmAccessibilityAlert(
                        "Delete your account?",
                        message: "Your photos, messages and subscriptions will be removed after 30 days."
                    )
                    .onSlideToConfirmStateChange { state in
                        guard state.phase == .success else { return }
                        Task {
                            try? await Task.sleep(for: .milliseconds(600))
                            withAnimation(.smooth) { isDeleted = true }
                        }
                    }
                    .id(attempt)
                    .accessibilityIdentifier("delete.control")
                    Text("Hold anywhere on the bar for 2 seconds, or drag the knob.")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.ink3)
                }
            }
        }
        .navigationTitle("Delete account")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func removal(_ symbol: String, _ title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).frame(width: 24).foregroundStyle(DS.ink2)
            Text(title).foregroundStyle(DS.ink)
            Spacer()
            Image(systemName: "minus.circle.fill").foregroundStyle(DS.danger)
        }
        .font(.system(size: 15))
        .frame(minHeight: 50)
    }
}

// MARK: - Emergency SOS

/// Hold only: the knob can't be dragged, so it never fires by accident.
struct EmergencyScenario: View {
    @State private var state = SlideToConfirmState.idle

    var body: some View {
        let isHolding = state.interaction == .holding
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                ForEach(0..<3) { ring in
                    Circle()
                        .stroke(DS.danger.opacity(0.18 - Double(ring) * 0.05), lineWidth: 2)
                        .frame(width: 150 + CGFloat(ring) * 54)
                        .scaleEffect(isHolding ? 1 + state.progress * 0.08 : 1)
                }
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: 0xFF6B4A), Color(hex: 0xE5383B)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 132)
                    .shadow(color: Color(hex: 0xE5383B).opacity(0.4), radius: 18, y: 8)
                Text(verbatim: "SOS")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .animation(.smooth(duration: 0.2), value: state.progress)
            VStack(spacing: 8) {
                Text(state.phase == .success ? "Your contacts have been alerted" : "Send an SOS to your emergency contacts")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.center)
                Text("Shares your live location for one hour. In this demo nothing is sent.")
                    .font(.dsBody)
                    .foregroundStyle(DS.ink2)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(DS.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            BottomConfirmBar {
                SlideToConfirm(labels: SlideToConfirmLabels(
                    "Hold for 3 seconds to send SOS",
                    holding: "Keep holding…",
                    processing: "Alerting contacts…",
                    success: "SOS sent"
                )) {
                    try await Task.sleep(for: .seconds(1.5))
                }
                .slideToConfirmConfiguration(.holdOnly.with {
                    $0.theme = .destructive
                    $0.holdDuration = 3
                    $0.holdHapticMarks = 5
                    $0.thickness = 72
                    $0.knobInset = 5
                    $0.labelSize = 16
                    $0.icons.idle = .systemImage("sos")
                    $0.successBehavior = .reset(after: 3)
                })
                .onSlideToConfirmStateChange { state = $0 }
                .accessibilityIdentifier("sos.control")
            }
        }
        .navigationTitle("Emergency SOS")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Garage

/// A vertical track that slides up, driving an illustration from the control's progress.
struct GarageScenario: View {
    @State private var state = SlideToConfirmState.idle

    var body: some View {
        let open = state.phase == .success ? 1 : (state.phase == .processing ? 0.92 : state.progress * 0.9)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(
                    eyebrow: "Smart home",
                    title: "Garage door",
                    lead: "Slide up, or hold the track, to open. The door follows the control's progress through `onSlideToConfirmStateChange`."
                )
                HStack(alignment: .bottom, spacing: 24) {
                    GarageDoor(openness: open)
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                    SlideToConfirm(labels: SlideToConfirmLabels(
                        "Slide up to open",
                        armed: "Release",
                        holding: "Opening…",
                        processing: "Opening…",
                        success: "Open"
                    )) {
                        try await Task.sleep(for: .seconds(1.2))
                    }
                    .slideToConfirmConfiguration {
                        $0.direction = .up
                        $0.thickness = 64
                        $0.labelSize = 14
                        $0.theme = .tinted(Color(hex: 0xF07F13))
                        $0.icons.idle = .arrow
                        $0.successBehavior = .reset(after: 3)
                    }
                    .onSlideToConfirmStateChange { state = $0 }
                    .frame(height: 280)
                    .accessibilityIdentifier("garage.control")
                }
                .card(padding: 20)
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill").foregroundStyle(DS.accent)
                    Text("Vertical tracks never mirror: up is up in every language.")
                        .font(.dsCaption)
                        .foregroundStyle(DS.ink2)
                }
            }
            .padding(DS.gutter)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(DS.background.ignoresSafeArea())
        .navigationTitle("Garage")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct GarageDoor: View {
    let openness: Double

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let opening = height - 28
            ZStack(alignment: .top) {
                // House outline
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(DS.surfaceRaised)
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DS.line))
                // Interior
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: [Color(hex: 0x1C2233), Color(hex: 0x313A52)], startPoint: .top, endPoint: .bottom))
                    .frame(width: width - 36, height: opening - 14)
                    .padding(.top, 28)
                    .overlay(alignment: .bottom) {
                        Image(systemName: "car.side.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(Color(hex: 0xF07F13))
                            .padding(.bottom, 10)
                            .opacity(openness)
                    }
                // Door panels
                VStack(spacing: 4) {
                    ForEach(0..<5) { _ in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(DS.surface)
                            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(DS.line2))
                    }
                }
                .frame(width: width - 36, height: (opening - 14) * (1 - openness))
                .padding(.top, 28)
                .clipped()
            }
        }
        .animation(.interactiveSpring(), value: openness)
        .accessibilityHidden(true)
    }
}
