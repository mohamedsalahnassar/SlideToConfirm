import Observation
import SwiftUI

/// App-wide settings and navigation. Launch arguments preselect a screen for UI tests and screenshots:
///
///     -screen send -appearance dark -language ar
@Observable
final class AppModel {
    enum Appearance: String, CaseIterable, Identifiable {
        case system, light, dark

        var id: String { rawValue }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }

        var title: LocalizedStringKey {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }

    enum Tab: String, Hashable {
        case showcase, scenarios, playground, states
    }

    var appearance: Appearance
    var language: DemoLanguage
    var tab: Tab
    var scenarioPath: [Scenario]
    /// Shows a bare stage with one control, for recording the README animation.
    let isRecordingStage: Bool
    /// Preselected surface for the States tab.
    let initialSurface: StageSurface

    init(defaults: UserDefaults = .standard) {
        appearance = defaults.string(forKey: "appearance").flatMap(Appearance.init(rawValue:)) ?? .system
        language = defaults.string(forKey: "language").flatMap(DemoLanguage.init(rawValue:)) ?? .english
        initialSurface = defaults.string(forKey: "surface").flatMap(StageSurface.init(rawValue:)) ?? .light

        let screen = defaults.string(forKey: "screen") ?? ""
        isRecordingStage = screen == "record"
        if let scenario = Scenario(rawValue: screen) {
            tab = .scenarios
            scenarioPath = [scenario]
        } else {
            tab = Tab(rawValue: screen) ?? .showcase
            scenarioPath = []
        }
    }
}

/// The demo content's language. Arabic also flips the layout to right-to-left.
enum DemoLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case arabic = "ar"

    var id: String { rawValue }

    var layoutDirection: LayoutDirection { self == .arabic ? .rightToLeft : .leftToRight }

    var locale: Locale { Locale(identifier: rawValue) }

    var title: String { self == .arabic ? "العربية" : "English" }
}

extension View {
    /// Applies the demo language's locale and layout direction.
    func demoLanguage(_ language: DemoLanguage) -> some View {
        environment(\.layoutDirection, language.layoutDirection)
            .environment(\.locale, language.locale)
    }
}
