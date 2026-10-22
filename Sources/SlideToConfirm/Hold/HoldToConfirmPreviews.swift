#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct HoldToConfirmButton_Previews: PreviewProvider {
    private static let labels = SlideToConfirmLabels(
        "Hold to send",
        holding: "Keep holding…",
        processing: "Sending…",
        success: "Sent",
        failure: "Not sent"
    )

    private static let states: [(String, HoldToConfirmPreviewState)] = [
        ("Idle", .idle),
        ("Holding", .holding(progress: 0.6)),
        ("Processing", .processing),
        ("Success", .success),
        ("Failure", .failure()),
        ("Disabled", .disabled),
    ]

    static var previews: some View {
        Group {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 24) {
                ForEach(Array(states.enumerated()), id: \.offset) { _, item in
                    HoldToConfirmButton(labels: labels, systemImage: "paperplane.fill") {}
                        .holdToConfirmPreviewState(item.1)
                }
            }
            .padding()
            .previewDisplayName("States")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 24) {
                ForEach(HoldToConfirmProgressStyle.allCases) { style in
                    HoldToConfirmButton(style.rawValue.capitalized, systemImage: "paperplane.fill") {}
                        .holdToConfirmProgressStyle(style)
                        .holdToConfirmPreviewState(.holding(progress: 0.6))
                }
            }
            .padding()
            .previewDisplayName("Progress styles")

            VStack(spacing: 32) {
                HoldToConfirmButton(labels: labels, systemImage: "paperplane.fill") {
                    try await Task.sleep(nanoseconds: 1_300_000_000)
                }
                .holdToConfirmConfiguration { $0.successBehavior = .reset(after: 2) }

                HoldToConfirmButton("Hold to delete") {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                }
                .holdToConfirmConfiguration(.destructive.with { $0.completionStyle = .burst })
            }
            .padding()
            .previewDisplayName("Live")

            Color.clear
                .overlay { ThumbReachOverlay(hand: .right) }
                .holdToConfirmOverlay(.thumbArc(.right)) {
                    HoldToConfirmButton("Hold to pay", systemImage: "creditcard.fill") {
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                    }
                }
                .previewDisplayName("Thumb arc")
        }
    }
}
#endif
