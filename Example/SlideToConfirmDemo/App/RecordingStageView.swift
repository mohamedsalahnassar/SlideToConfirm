import SwiftUI

/// A bare stage with the hero control, used to record the README animation (`-screen record`).
struct RecordingStageView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 18) {
                Eyebrow("SlideToConfirm")
                Text("Slide it, or just hold it.")
                    .font(.system(size: 30, weight: .bold))
                    .tracking(-0.8)
                    .foregroundStyle(DS.ink)
                HeroStage()
            }
            .padding(.horizontal, DS.gutter)
            .padding(.vertical, 24)
            .frame(maxWidth: 560)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("record.stage")
        }
        .environment(\.layoutDirection, model.language.layoutDirection)
    }
}
