#if canImport(SwiftUI)
import SwiftUI

/// Where a floating ``HoldToConfirmButton`` sits on screen, chosen for one-handed reach.
///
/// Every placement keeps the circle in the ``ThumbReach/Zone/natural`` zone of the hand it names
/// on a phone in portrait. Placements name a hand, not leading or trailing, because reach is
/// physical: in a right-to-left language the right thumb still rests on the right.
///
/// ```swift
/// ReviewScreen()
///     .holdToConfirmOverlay(.thumbArc(.right)) {
///         HoldToConfirmButton("Hold to pay", systemImage: "creditcard.fill") { try await pay() }
///     }
/// ```
public enum HoldToConfirmPlacement: Hashable, Sendable {
    /// Centered above the bottom edge. Natural for either hand, and where people look for the
    /// primary action. The safest default.
    case bottomCenter
    /// In the bottom corner on the side of `hand`, where floating action buttons live.
    case bottomCorner(ThumbReach.Hand)
    /// On the arc the thumb rests on, about two thirds of the way down and in from the edge on the
    /// side of `hand`. The most comfortable spot to keep a finger down for a second or two.
    case thumbArc(ThumbReach.Hand)
    /// Against the edge on the side of `hand`, a little below the middle, where the thumb wraps
    /// around the phone. Echoes a side bar, and leaves the bottom free for a tab bar.
    case edge(ThumbReach.Hand)

    /// Every placement, for both hands.
    public static var allCases: [HoldToConfirmPlacement] {
        [.bottomCenter]
            + ThumbReach.Hand.allCases.flatMap { [.bottomCorner($0), .thumbArc($0), .edge($0)] }
    }

    /// The hand the placement favors, or `nil` when it suits either.
    public var hand: ThumbReach.Hand? {
        switch self {
        case .bottomCenter: return nil
        case let .bottomCorner(hand), let .thumbArc(hand), let .edge(hand): return hand
        }
    }

    /// The same placement for the other hand.
    public var mirrored: HoldToConfirmPlacement {
        switch self {
        case .bottomCenter: return .bottomCenter
        case let .bottomCorner(hand): return .bottomCorner(hand.opposite)
        case let .thumbArc(hand): return .thumbArc(hand.opposite)
        case let .edge(hand): return .edge(hand.opposite)
        }
    }

    /// The alignment and insets that put an item at this placement in a container of `size`,
    /// in left-to-right coordinates: `leading` is the left edge.
    func frame(in size: CGSize, margin: CGFloat) -> (alignment: Alignment, insets: EdgeInsets) {
        func side(_ hand: ThumbReach.Hand, vertical: VerticalAlignment) -> Alignment {
            Alignment(horizontal: hand == .right ? .trailing : .leading, vertical: vertical)
        }
        func insets(_ hand: ThumbReach.Hand, side inset: CGFloat, top: CGFloat = 0, bottom: CGFloat = 0) -> EdgeInsets {
            EdgeInsets(top: top, leading: hand == .left ? inset : 0, bottom: bottom, trailing: hand == .right ? inset : 0)
        }
        switch self {
        case .bottomCenter:
            return (.bottom, EdgeInsets(top: 0, leading: 0, bottom: margin, trailing: 0))
        case let .bottomCorner(hand):
            return (side(hand, vertical: .bottom), insets(hand, side: margin, bottom: margin))
        case let .thumbArc(hand):
            return (
                side(hand, vertical: .bottom),
                insets(hand, side: max(margin, size.width * 0.1), bottom: max(margin, size.height * 0.2))
            )
        case let .edge(hand):
            // Twice the offset as top inset moves the centered item down by that offset.
            return (side(hand, vertical: .center), insets(hand, side: margin * 0.6, top: size.height * 0.2))
        }
    }
}

extension View {
    /// Floats `content`, typically a ``HoldToConfirmButton``, over this view at `placement`.
    ///
    /// The overlay respects the safe area and keeps the content's own layout direction.
    ///
    /// - Parameters:
    ///   - placement: Where the content sits.
    ///   - margin: The distance from the edges the placement hugs, in points.
    ///   - content: The floating content.
    public func holdToConfirmOverlay<Content: View>(
        _ placement: HoldToConfirmPlacement,
        margin: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) -> some View {
        modifier(HoldToConfirmOverlayModifier(placement: placement, margin: margin, overlay: content()))
    }
}

private struct HoldToConfirmOverlayModifier<Overlay: View>: ViewModifier {
    let placement: HoldToConfirmPlacement
    let margin: CGFloat
    let overlay: Overlay

    @Environment(\.layoutDirection) private var layoutDirection

    func body(content: Content) -> some View {
        content.overlay {
            GeometryReader { proxy in
                let frame = placement.frame(in: proxy.size, margin: margin)
                overlay
                    .environment(\.layoutDirection, layoutDirection)
                    .padding(frame.insets)
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: frame.alignment)
            }
            // Placements are physical, so lay them out left to right in every language.
            .environment(\.layoutDirection, .leftToRight)
        }
    }
}

/// A heat map of ``ThumbReach`` zones, for checking a layout against one-handed reach.
///
/// Green is natural, yellow a stretch or a curl, red hard to reach. Overlay it on a screen while
/// you design, then take it out:
///
/// ```swift
/// ReviewScreen()
///     .overlay { ThumbReachOverlay(hand: .right).ignoresSafeArea() }
/// ```
public struct ThumbReachOverlay: View {
    private let hand: ThumbReach.Hand
    private let opacity: Double

    /// Creates a heat map for `hand`.
    ///
    /// - Parameter opacity: How strongly the zones tint the screen.
    public init(hand: ThumbReach.Hand = .right, opacity: Double = 0.3) {
        self.hand = hand
        self.opacity = opacity
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let pivot = ThumbReach.pivot(in: size, hand: hand)
            let unit = ThumbReach.unit(for: size)
            ZStack {
                Rectangle().fill(Color.red)
                disc(around: pivot, radius: unit * ThumbReach.stretchRadius).fill(Color.yellow)
                disc(around: pivot, radius: unit * ThumbReach.naturalRadius).fill(Color.green)
                disc(around: pivot, radius: unit * ThumbReach.curlRadius).fill(Color.yellow)
            }
            .frame(width: size.width, height: size.height)
            .clipped()
            .opacity(opacity)
        }
        .environment(\.layoutDirection, .leftToRight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func disc(around center: CGPoint, radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    }
}
#endif
