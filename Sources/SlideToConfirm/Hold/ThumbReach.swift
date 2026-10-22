import Foundation

/// A model of where the thumb reaches on a phone held in one hand.
///
/// Reach is measured from the base of the thumb, just past the bottom corner on the side of the
/// holding hand, in multiples of the screen's shorter side. Points between 0.3 and 0.95 of that
/// from the base are ``Zone/natural``; points closer in make the thumb curl, and points up to 1.35
/// away make it stretch; anything further needs the other hand or a change of grip.
///
/// The model is a rule of thumb for phones, not a measurement of any particular hand. Use it to
/// keep controls people hold down, which they can't do mid-stretch, out of the hard zone.
///
/// ```swift
/// ThumbReach.zone(at: buttonCenter, in: screen.size, hand: .right) // .natural
/// ```
public enum ThumbReach {

    /// The hand holding the phone.
    ///
    /// Reach is physical, so a hand never flips in right-to-left languages.
    public enum Hand: String, Sendable, Hashable, CaseIterable, Identifiable {
        case right, left

        public var id: Self { self }

        /// The other hand.
        public var opposite: Hand { self == .right ? .left : .right }
    }

    /// How easily the thumb reaches a point.
    public enum Zone: Int, Sendable, Hashable, CaseIterable, Identifiable, Comparable {
        /// Reached without shifting the grip. Put confirming controls here.
        case natural
        /// Reached by stretching the thumb out or curling it in. Fine for a tap, tiring for a hold.
        case stretch
        /// Needs the other hand or a change of grip.
        case hard

        public var id: Self { self }

        public static func < (lhs: Zone, rhs: Zone) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    /// Closer to the base than this, the thumb has to curl in.
    public static let curlRadius: Double = 0.3
    /// The outer edge of the natural zone.
    public static let naturalRadius: Double = 0.95
    /// The outer edge of the stretch zone.
    public static let stretchRadius: Double = 1.35

    /// The length all radii are multiples of: the screen's shorter side.
    public static func unit(for size: CGSize) -> CGFloat {
        max(1, min(size.width, size.height))
    }

    /// Where the base of the thumb sits, in the screen's coordinates with the origin at the top left.
    public static func pivot(in size: CGSize, hand: Hand) -> CGPoint {
        let overhang = unit(for: size) * 0.02
        return CGPoint(x: hand == .right ? size.width + overhang : -overhang, y: size.height)
    }

    /// How easily the thumb of `hand` reaches `point` on a screen of `size`.
    ///
    /// - Parameter point: A point in the screen's coordinates, with the origin at the top left.
    public static func zone(at point: CGPoint, in size: CGSize, hand: Hand) -> Zone {
        let pivot = pivot(in: size, hand: hand)
        let dx = Double(point.x - pivot.x)
        let dy = Double(point.y - pivot.y)
        let reach = (dx * dx + dy * dy).squareRoot() / Double(unit(for: size))
        if reach < curlRadius { return .stretch }
        if reach <= naturalRadius { return .natural }
        if reach <= stretchRadius { return .stretch }
        return .hard
    }
}
