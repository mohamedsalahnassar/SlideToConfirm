import SwiftUI

@main
struct SlideToConfirmDemoApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            Group {
                switch model.recordingStage {
                case .slide: RecordingStageView()
                case .hold: HoldRecordingStageView()
                case nil: RootView()
                }
            }
            .environment(model)
            .preferredColorScheme(model.appearance.colorScheme)
            .tint(DS.accent)
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.tab) {
            ShowcaseView()
                .tabItem { Label("Showcase", systemImage: "sparkles") }
                .tag(AppModel.Tab.showcase)
            HoldView()
                .tabItem { Label("Hold", systemImage: "circle.circle.fill") }
                .tag(AppModel.Tab.hold)
            ScenariosView()
                .tabItem { Label("Scenarios", systemImage: "square.stack.3d.up.fill") }
                .tag(AppModel.Tab.scenarios)
            PlaygroundView()
                .tabItem { Label("Playground", systemImage: "slider.horizontal.3") }
                .tag(AppModel.Tab.playground)
            StatesGalleryView()
                .tabItem { Label("States", systemImage: "square.grid.2x2.fill") }
                .tag(AppModel.Tab.states)
        }
    }
}

/// A toolbar menu for appearance and language, shared by every tab.
struct AppSettingsMenu: View {
    @Environment(AppModel.self) private var model
    var showsLanguage = false

    var body: some View {
        @Bindable var model = model
        Menu {
            Picker("Appearance", selection: $model.appearance) {
                ForEach(AppModel.Appearance.allCases) { appearance in
                    Text(appearance.title).tag(appearance)
                }
            }
            if showsLanguage {
                Picker("Language", selection: $model.language) {
                    ForEach(DemoLanguage.allCases) { language in
                        Text(verbatim: language.title).tag(language)
                    }
                }
            }
        } label: {
            Image(systemName: "circle.lefthalf.filled")
                .accessibilityLabel("Appearance")
        }
    }
}
