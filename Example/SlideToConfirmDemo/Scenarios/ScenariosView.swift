import SlideToConfirm
import SwiftUI

/// Every real-world use case the demo covers. Raw values double as `-screen` launch arguments.
enum Scenario: String, CaseIterable, Identifiable, Hashable {
    case sendMoney = "send"
    case unlock
    case checkout
    case deleteAccount = "delete"
    case emergency = "sos"
    case garage
    case workout
    case tabZone = "tabzone"
    case uikit

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .sendMoney: return "Send money"
        case .unlock: return "Unlock a door"
        case .checkout: return "Pay on a brand surface"
        case .deleteAccount: return "Delete an account"
        case .emergency: return "Emergency SOS"
        case .garage: return "Open the garage"
        case .workout: return "End a workout"
        case .tabZone: return "Vertical bar · iPhone Duo"
        case .uikit: return "UIKit integration"
        }
    }

    var subtitle: LocalizedStringKey {
        switch self {
        case .sendMoney: return "Review, slide or hold, then a receipt. Async action, failure and retry, Arabic and right-to-left."
        case .unlock: return "Slide only, with a lock knob that opens on success and a glow that tracks progress."
        case .checkout: return "A translucent track and white knob on a colored background, with a custom card knob."
        case .deleteAccount: return "Destructive theme, a calm fill hold of 2 seconds and an accessibility alert as a second step."
        case .emergency: return "Hold only: the knob can't be dragged, so it never fires by accident. A 3-second countdown."
        case .garage: return "A vertical track that slides up, driving an illustration from the control's progress."
        case .workout: return "A hold circle that counts down three seconds, so a pocket tap pauses but never ends the run."
        case .tabZone: return "A pull-down track in the tab zone of a trailing vertical bar, or a 48 pt hold ring in three positions."
        case .uikit: return "SlideToConfirmControl in a UIKit view controller with Auto Layout and target-action."
        }
    }

    var symbol: String {
        switch self {
        case .sendMoney: return "paperplane.fill"
        case .unlock: return "lock.open.fill"
        case .checkout: return "creditcard.fill"
        case .deleteAccount: return "trash.fill"
        case .emergency: return "sos"
        case .garage: return "door.garage.open"
        case .workout: return "figure.run"
        case .tabZone: return "sidebar.right"
        case .uikit: return "square.stack.3d.down.right.fill"
        }
    }

    var colors: [Color] {
        switch self {
        case .sendMoney: return [Color(hex: 0x4C6BFF), Color(hex: 0x2343D6)]
        case .unlock: return [Color(hex: 0x34C77B), Color(hex: 0x16884A)]
        case .checkout: return [Color(hex: 0x8B5CF6), Color(hex: 0x4F46E5)]
        case .deleteAccount: return [Color(hex: 0xFF6B6B), Color(hex: 0xD92D3A)]
        case .emergency: return [Color(hex: 0xFF8A3D), Color(hex: 0xE5383B)]
        case .garage: return [Color(hex: 0xFFB547), Color(hex: 0xF07F13)]
        case .workout: return [Color(hex: 0xB4F05A), Color(hex: 0x2FA866)]
        case .tabZone: return [Color(hex: 0x5B77FF), Color(hex: 0x13246F)]
        case .uikit: return [Color(hex: 0x6E7891), Color(hex: 0x3A4256)]
        }
    }

    var tags: [LocalizedStringKey] {
        switch self {
        case .sendMoney: return ["Combined hold", "Async", "Failure", "RTL"]
        case .unlock: return ["Slide only", "Custom icons", "Positive"]
        case .checkout: return ["onColor theme", "Custom knob"]
        case .deleteAccount: return ["Fill hold", "Destructive", "A11y alert"]
        case .emergency: return ["Hold only", "Large"]
        case .garage: return ["Slide up", "State observer"]
        case .workout: return ["Hold circle", "Countdown", "Morph"]
        case .tabZone: return ["Slide down", "Hold ring", "Vertical bar"]
        case .uikit: return ["UIKit", "Auto Layout"]
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .sendMoney: SendMoneyScenario()
        case .unlock: UnlockScenario()
        case .checkout: CheckoutScenario()
        case .deleteAccount: DeleteAccountScenario()
        case .emergency: EmergencyScenario()
        case .garage: GarageScenario()
        case .workout: WorkoutScenario()
        case .tabZone: TabZoneScenario()
        case .uikit: UIKitScenario()
        }
    }
}

struct ScenariosView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $model.scenarioPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader(
                        eyebrow: "Scenarios",
                        title: "Built for real screens",
                        lead: "Each scenario is a complete screen showing one way to configure and place the control."
                    )
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 14)], spacing: 14) {
                        ForEach(Scenario.allCases) { scenario in
                            NavigationLink(value: scenario) {
                                ScenarioCard(scenario: scenario)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("scenario.\(scenario.rawValue)")
                        }
                    }
                }
                .padding(.horizontal, DS.gutter)
                .padding(.vertical, 12)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .background(DS.background.ignoresSafeArea())
            .navigationTitle("Scenarios")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { AppSettingsMenu(showsLanguage: true) }
            }
            .navigationDestination(for: Scenario.self) { scenario in
                scenario.destination
            }
        }
    }
}

private struct ScenarioCard: View {
    let scenario: Scenario

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            IconTile(symbol: scenario.symbol, colors: scenario.colors)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(scenario.title)
                        .font(.dsHeadline)
                        .foregroundStyle(DS.ink)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.forward")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DS.ink3)
                }
                Text(scenario.subtitle)
                    .font(.dsCaption)
                    .foregroundStyle(DS.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                FlowLayout(spacing: 6) {
                    ForEach(Array(scenario.tags.enumerated()), id: \.offset) { _, tag in
                        Text(tag)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(DS.accentInk)
                            .padding(.horizontal, 8)
                            .frame(height: 22)
                            .background(DS.accentSoft, in: Capsule())
                    }
                }
                .padding(.top, 4)
            }
        }
        .card(padding: 16)
        .contentShape(Rectangle())
    }
}

/// A pinned bottom area for a confirm control, above the home indicator.
struct BottomConfirmBar<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 10) {
            content
        }
        .padding(.horizontal, DS.gutter)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(.bar)
        .overlay(alignment: .top) { Divider().overlay(DS.line) }
    }
}

/// A row in a details card.
struct DetailRow<Value: View>: View {
    let title: Text
    let value: Value

    var body: some View {
        HStack(spacing: 12) {
            title.foregroundStyle(DS.ink2)
            Spacer(minLength: 12)
            value.fontWeight(.semibold).foregroundStyle(DS.ink).multilineTextAlignment(.trailing)
        }
        .font(.system(size: 15))
        .frame(minHeight: 48)
    }
}
