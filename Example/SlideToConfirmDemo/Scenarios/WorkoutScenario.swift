import SlideToConfirm
import SwiftUI

/// Ending a run: a tap pauses, but only a three-second hold ends it, so a stray touch in a pocket
/// never throws a workout away. The circle counts the seconds down and morphs into "Saved".
struct WorkoutScenario: View {
    @State private var startedAt = Date().addingTimeInterval(-(32 * 60 + 18))
    @State private var pausedAt: Date?
    @State private var isSaved = false

    private let lime = Color(hex: 0xB4F05A)

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x0B1A12), Color(hex: 0x050807)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            if isSaved {
                summary
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                running
                    .transition(.opacity)
            }
        }
        .environment(\.colorScheme, .dark)
        .navigationTitle("Outdoor run")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: isSaved)
    }

    // MARK: Running

    private var running: some View {
        VStack(spacing: 0) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(verbatim: elapsed(at: pausedAt ?? context.date))
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(pausedAt == nil ? lime : .white.opacity(0.5))
                    .contentTransition(.numericText())
            }
            .padding(.top, 24)
            Text(pausedAt == nil ? "Elapsed" : "Paused")
                .font(.system(size: 13, weight: .semibold))
                .textCase(.uppercase)
                .tracking(1)
                .foregroundStyle(.white.opacity(0.55))

            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    stat("5.42", unit: "km", title: "Distance")
                    stat("5'57\"", unit: "/km", title: "Pace")
                }
                GridRow {
                    stat("148", unit: "bpm", title: "Heart rate")
                    stat("386", unit: "kcal", title: "Energy")
                }
            }
            .padding(.top, 32)

            Spacer(minLength: 24)

            HStack(alignment: .top, spacing: 44) {
                VStack(spacing: 12) {
                    Button {
                        if let pausedAt {
                            // Resume: the paused time doesn't count.
                            startedAt = startedAt.addingTimeInterval(Date().timeIntervalSince(pausedAt))
                            self.pausedAt = nil
                        } else {
                            pausedAt = Date()
                        }
                    } label: {
                        Image(systemName: pausedAt == nil ? "pause.fill" : "play.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 88, height: 88)
                            .background(lime, in: Circle())
                    }
                    .padding(11)
                    .accessibilityLabel(pausedAt == nil ? "Pause" : "Resume")
                    .accessibilityIdentifier("workout.pause")
                    Text(pausedAt == nil ? "Pause" : "Resume")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }

                HoldToConfirmButton(labels: .endWorkout, systemImage: "stop.fill") {
                    try await Task.sleep(for: .seconds(1))
                }
                .holdToConfirmConfiguration {
                    $0.holdDuration = 3
                    $0.progressStyle = .countdown
                    $0.completionStyle = .morph
                    $0.theme = .tinted(Color(hex: 0xFF5A4E))
                    $0.icons.idle = .systemImage("stop.fill")
                }
                .onHoldToConfirmStateChange { state in
                    guard state.phase == .success else { return }
                    Task {
                        try? await Task.sleep(for: .milliseconds(900))
                        isSaved = true
                    }
                }
                .accessibilityIdentifier("workout.end")
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, DS.gutter)
        .frame(maxWidth: 560)
    }

    private func stat(_ value: String, unit: String, title: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(verbatim: value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(verbatim: unit)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .environment(\.layoutDirection, .leftToRight)
    }

    private func elapsed(at date: Date) -> String {
        let seconds = max(0, Int(date.timeIntervalSince(startedAt)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: Saved

    private var summary: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 72, height: 72)
                .background(lime, in: Circle())
            Text("Run saved")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
            Text(verbatim: "5.42 km · \(elapsed(at: pausedAt ?? Date()))")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            Button {
                startedAt = Date().addingTimeInterval(-(32 * 60 + 18))
                pausedAt = nil
                isSaved = false
            } label: {
                Text("Start another")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: 280, minHeight: 52)
                    .background(lime, in: Capsule())
            }
            .padding(.top, 18)
            .accessibilityIdentifier("workout.again")
        }
        .padding(DS.gutter)
    }
}

extension SlideToConfirmLabels {
    static var endWorkout: SlideToConfirmLabels {
        SlideToConfirmLabels(
            "Hold to end",
            holding: "Keep holding…",
            processing: "Saving…",
            success: "Saved",
            accessibilityHint: "Double-tap to end the workout.",
            tapHint: "Hold to end · tap Pause"
        )
    }
}
