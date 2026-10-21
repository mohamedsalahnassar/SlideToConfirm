#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Plays haptics for a confirm control's key moments.
///
/// ```swift
/// // Off
/// .slideToConfirmHaptics(.disabled)
///
/// // Your own engine
/// .slideToConfirmHaptics(.custom { event in
///     if event == .success { myHaptics.playSuccess() }
/// })
/// ```
public struct SlideToConfirmHaptics {
    let play: (@MainActor (SlideToConfirmHapticEvent) -> Void)?
    let prepare: (@MainActor () -> Void)?

    /// Feedback generators on iPhone, the trackpad on Mac. The default.
    ///
    /// | Event | iPhone |
    /// | --- | --- |
    /// | Hold began | light impact |
    /// | Hold progress | soft impact, stronger each mark |
    /// | Armed | medium impact |
    /// | Confirmed | rigid impact |
    /// | Success | success notification |
    /// | Failure | error notification |
    public static var automatic: SlideToConfirmHaptics {
        SlideToConfirmHaptics(
            play: { SystemHaptics.play($0) },
            prepare: { SystemHaptics.prepare() }
        )
    }

    /// No haptics.
    public static var disabled: SlideToConfirmHaptics {
        SlideToConfirmHaptics(play: nil, prepare: nil)
    }

    /// Calls `handler` for each event instead of playing system haptics.
    public static func custom(_ handler: @escaping @MainActor (SlideToConfirmHapticEvent) -> Void) -> SlideToConfirmHaptics {
        SlideToConfirmHaptics(play: handler, prepare: nil)
    }
}

@MainActor
enum SystemHaptics {
    #if os(iOS)
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let notification = UINotificationFeedbackGenerator()
    #endif

    static func prepare() {
        #if os(iOS)
        light.prepare()
        medium.prepare()
        #endif
    }

    static func play(_ event: SlideToConfirmHapticEvent) {
        #if os(iOS)
        switch event {
        case .holdBegan:
            light.impactOccurred(intensity: 0.7)
            soft.prepare()
        case let .holdProgress(fraction):
            soft.impactOccurred(intensity: CGFloat(0.4 + 0.5 * fraction))
            rigid.prepare()
        case .armed:
            medium.impactOccurred()
            rigid.prepare()
        case .confirmed:
            rigid.impactOccurred(intensity: 0.85)
            notification.prepare()
        case .success:
            notification.notificationOccurred(.success)
        case .failure:
            notification.notificationOccurred(.error)
        }
        #elseif os(macOS)
        let performer = NSHapticFeedbackManager.defaultPerformer
        switch event {
        case .armed, .confirmed, .success, .failure:
            performer.perform(.levelChange, performanceTime: .now)
        case .holdBegan, .holdProgress:
            performer.perform(.alignment, performanceTime: .now)
        }
        #endif
    }
}
#endif
