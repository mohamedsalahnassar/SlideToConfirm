#if canImport(SwiftUI)
import SwiftUI

/// A drop shadow.
public struct SlideToConfirmShadow: Hashable {
    public var color: Color
    public var radius: CGFloat
    public var x: CGFloat
    public var y: CGFloat

    public init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

/// The colors of a confirm control in one appearance.
///
/// Start from a built-in palette and change what you need:
///
/// ```swift
/// var palette = SlideToConfirmPalette.light(accent: .orange)
/// palette.success = .mint
/// ```
public struct SlideToConfirmPalette: Hashable {
    /// The bare track.
    public var track: Color
    /// A hairline around the track.
    public var trackBorder: Color
    /// The shadow under the track.
    public var trackShadow: SlideToConfirmShadow?
    /// The soft fill that follows the knob while dragging.
    public var fill: Color
    /// The soft fill once a drag passes the commit threshold.
    public var armedFill: Color
    /// The solid fill drawn while holding and processing.
    public var solidFill: Color
    /// Labels and the knob drawn on the solid fill.
    public var onSolidFill: Color
    /// The knob.
    public var knob: Color
    /// The icon and countdown ring on the knob.
    public var knobIcon: Color
    /// The shadow under the knob.
    public var knobShadow: SlideToConfirmShadow?
    /// The label on the bare track.
    public var label: Color
    /// The dim part of the idle shimmer.
    public var dimmedLabel: Color
    /// The failure label.
    public var failureLabel: Color
    /// The unfilled part of the countdown ring on the regular knob.
    public var ringTrack: Color
    /// The unfilled part of the countdown ring on the inverted knob, over the solid fill.
    public var invertedRingTrack: Color
    /// The track after success.
    public var success: Color
    /// The label and knob after success.
    public var onSuccess: Color

    public init(
        track: Color,
        trackBorder: Color,
        trackShadow: SlideToConfirmShadow?,
        fill: Color,
        armedFill: Color,
        solidFill: Color,
        onSolidFill: Color,
        knob: Color,
        knobIcon: Color,
        knobShadow: SlideToConfirmShadow?,
        label: Color,
        dimmedLabel: Color,
        failureLabel: Color,
        ringTrack: Color,
        invertedRingTrack: Color,
        success: Color,
        onSuccess: Color
    ) {
        self.track = track
        self.trackBorder = trackBorder
        self.trackShadow = trackShadow
        self.fill = fill
        self.armedFill = armedFill
        self.solidFill = solidFill
        self.onSolidFill = onSolidFill
        self.knob = knob
        self.knobIcon = knobIcon
        self.knobShadow = knobShadow
        self.label = label
        self.dimmedLabel = dimmedLabel
        self.failureLabel = failureLabel
        self.ringTrack = ringTrack
        self.invertedRingTrack = invertedRingTrack
        self.success = success
        self.onSuccess = onSuccess
    }
}

extension SlideToConfirmPalette {
    /// A white track with an `accent` knob and fills, for light backgrounds.
    public static func light(accent: Color, success: Color? = nil) -> SlideToConfirmPalette {
        SlideToConfirmPalette(
            track: .white,
            trackBorder: .stcInk.opacity(0.08),
            trackShadow: SlideToConfirmShadow(color: .stcInk.opacity(0.08), radius: 9, y: 4),
            fill: accent.opacity(0.10),
            armedFill: accent.opacity(0.18),
            solidFill: accent,
            onSolidFill: .white,
            knob: accent,
            knobIcon: .white,
            knobShadow: SlideToConfirmShadow(color: accent.opacity(0.35), radius: 4, y: 2),
            label: .stcInk,
            dimmedLabel: .stcInk.opacity(0.58),
            failureLabel: Color(stcHex: 0xC62F3A),
            ringTrack: .white.opacity(0.32),
            invertedRingTrack: accent.opacity(0.2),
            success: success ?? .stcSuccess,
            onSuccess: .white
        )
    }

    /// A deep track with an `accent` knob and fills, for dark backgrounds.
    public static func dark(accent: Color, success: Color? = nil) -> SlideToConfirmPalette {
        SlideToConfirmPalette(
            track: Color(stcHex: 0x1A2030),
            trackBorder: .white.opacity(0.08),
            trackShadow: nil,
            fill: accent.opacity(0.22),
            armedFill: accent.opacity(0.34),
            solidFill: accent,
            onSolidFill: .white,
            knob: accent,
            knobIcon: .white,
            knobShadow: SlideToConfirmShadow(color: .black.opacity(0.45), radius: 5, y: 2),
            label: Color(stcHex: 0xF3F5FA),
            dimmedLabel: Color(stcHex: 0xF3F5FA).opacity(0.56),
            failureLabel: Color(stcHex: 0xFF6B73),
            ringTrack: .white.opacity(0.32),
            invertedRingTrack: accent.opacity(0.25),
            success: success ?? .stcSuccess,
            onSuccess: .white
        )
    }

    /// A translucent track with a `knob`-colored knob, for colored or photographic surfaces.
    ///
    /// - Parameters:
    ///   - accent: The surface's brand color, used for the knob icon and labels on the fill.
    ///   - knob: The knob and the solid fill. Default white.
    public static func onColor(accent: Color, knob: Color = .white, success: Color? = nil) -> SlideToConfirmPalette {
        SlideToConfirmPalette(
            track: knob.opacity(0.16),
            trackBorder: knob.opacity(0.34),
            trackShadow: nil,
            fill: knob.opacity(0.16),
            armedFill: knob.opacity(0.28),
            solidFill: knob,
            onSolidFill: accent,
            knob: knob,
            knobIcon: accent,
            knobShadow: SlideToConfirmShadow(color: .black.opacity(0.25), radius: 5, y: 3),
            label: knob,
            dimmedLabel: knob.opacity(0.6),
            failureLabel: Color(stcHex: 0xFFB4B8),
            ringTrack: accent.opacity(0.22),
            invertedRingTrack: knob.opacity(0.4),
            success: success ?? .stcSuccess,
            onSuccess: .white
        )
    }
}

/// Palettes for light and dark appearance. The control picks one from the environment's color scheme.
public struct SlideToConfirmTheme: Hashable {
    public var light: SlideToConfirmPalette
    public var dark: SlideToConfirmPalette

    public init(light: SlideToConfirmPalette, dark: SlideToConfirmPalette) {
        self.light = light
        self.dark = dark
    }

    /// One palette for both appearances.
    public init(_ palette: SlideToConfirmPalette) {
        self.init(light: palette, dark: palette)
    }

    /// The palette for `colorScheme`.
    public func palette(for colorScheme: ColorScheme) -> SlideToConfirmPalette {
        colorScheme == .dark ? dark : light
    }

    /// A light and a dark palette built around one accent color.
    ///
    /// - Parameters:
    ///   - accent: The knob and fill color in light appearance.
    ///   - dark: The knob and fill color in dark appearance. Defaults to `accent`.
    public static func tinted(_ accent: Color, dark: Color? = nil) -> SlideToConfirmTheme {
        SlideToConfirmTheme(light: .light(accent: accent), dark: .dark(accent: dark ?? accent))
    }

    /// A translucent track and white knob for colored surfaces in both appearances.
    ///
    /// - Parameter accent: The surface's brand color, used for the knob icon and the label on the fill.
    public static func onColor(_ accent: Color) -> SlideToConfirmTheme {
        SlideToConfirmTheme(.onColor(accent: accent))
    }

    /// Deep blue on white in light appearance, bright blue on navy in dark. The default.
    public static var standard: SlideToConfirmTheme { .tinted(Color(stcHex: 0x2343D6), dark: Color(stcHex: 0x3D5CF5)) }

    /// For a deep blue brand surface: a translucent track and a white knob.
    public static var brand: SlideToConfirmTheme { .onColor(Color(stcHex: 0x2343D6)) }

    /// Follows the app's accent color.
    public static var accent: SlideToConfirmTheme { .tinted(.accentColor) }

    /// Red, for actions that destroy data.
    public static var destructive: SlideToConfirmTheme { .tinted(Color(stcHex: 0xD92D3A), dark: Color(stcHex: 0xF0525C)) }

    /// Green, for positive actions such as unlocking or accepting.
    public static var positive: SlideToConfirmTheme { .tinted(Color(stcHex: 0x16884A), dark: Color(stcHex: 0x2FB36B)) }

    /// Near-black on white in light appearance, white on charcoal in dark.
    public static var monochrome: SlideToConfirmTheme {
        var dark = SlideToConfirmPalette.dark(accent: Color(stcHex: 0xF3F5FA))
        dark.knobIcon = Color(stcHex: 0x0E1220)
        dark.onSolidFill = Color(stcHex: 0x0E1220)
        dark.ringTrack = Color(stcHex: 0x0E1220).opacity(0.25)
        dark.invertedRingTrack = Color(stcHex: 0x0E1220).opacity(0.25)
        return SlideToConfirmTheme(light: .light(accent: Color(stcHex: 0x0E1220)), dark: dark)
    }
}

extension Color {
    /// The deep ink the default palettes use for text.
    static var stcInk: Color { Color(stcHex: 0x0E1220) }
    /// The default success green.
    static var stcSuccess: Color { Color(stcHex: 0x1A7F45) }

    init(stcHex hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
#endif
