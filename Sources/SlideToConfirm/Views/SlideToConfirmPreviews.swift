#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct SlideToConfirm_Previews: PreviewProvider {
    private static let labels = SlideToConfirmLabels(
        "Slide or hold to send",
        armed: "Release to send",
        holding: "Keep holding…",
        processing: "Sending…",
        success: "Sent",
        failure: "Not sent · try again"
    )

    private static let states: [(String, SlideToConfirmPreviewState)] = [
        ("Idle", .idle),
        ("Holding · early", .holding(progress: 0.24)),
        ("Holding · late", .holding(progress: 0.76)),
        ("Dragging", .dragging()),
        ("Armed", .armed()),
        ("Processing", .processing),
        ("Success", .success),
        ("Failure", .failure()),
        ("Disabled", .disabled),
    ]

    static var previews: some View {
        Group {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(states.enumerated()), id: \.offset) { _, item in
                        Text(verbatim: item.0).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        SlideToConfirm(labels: labels) {}
                            .slideToConfirmPreviewState(item.1)
                    }
                }
                .padding()
            }
            .previewDisplayName("States")

            VStack(spacing: 24) {
                SlideToConfirm(labels: labels) {
                    try await Task.sleep(nanoseconds: 1_300_000_000)
                }
                .slideToConfirmConfiguration { $0.successBehavior = .reset(after: 2) }

                SlideToConfirm("Hold to delete") {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                }
                .slideToConfirmConfiguration(.holdOnly.with { $0.theme = .destructive })
            }
            .padding()
            .previewDisplayName("Live")

            HStack(spacing: 24) {
                SlideToConfirm(labels: labels) {}
                    .slideToConfirmConfiguration(.verticalBar)
                    .slideToConfirmPreviewState(.holding(progress: 0.6))
                SlideToConfirm(labels: labels) {}
                    .slideToConfirmConfiguration(.verticalBar.with { $0.direction = .up })
                    .slideToConfirmPreviewState(.armed())
            }
            .frame(height: 300)
            .padding()
            .previewDisplayName("Vertical")

            VStack(spacing: 14) {
                SlideToConfirm(labels: labels) {}
                    .slideToConfirmPreviewState(.holding(progress: 0.6))
                SlideToConfirm(labels: labels) {}
                    .slideToConfirmTheme(.brand)
                    .slideToConfirmPreviewState(.idle)
                    .padding()
                    .background(Color(stcHex: 0x13246F), in: RoundedRectangle(cornerRadius: 20))
            }
            .padding()
            .background(Color(stcHex: 0x07090F))
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Dark and brand")

            SlideToConfirm(labels: SlideToConfirmLabels(idle: Text(verbatim: "اسحب أو اضغط مطولاً للإرسال"))) {}
                .slideToConfirmPreviewState(.holding(progress: 0.5))
                .environment(\.layoutDirection, .rightToLeft)
                .padding()
                .previewDisplayName("Right to left")
        }
    }
}
#endif
