#if canImport(SwiftUI)
import SwiftUI

/// Reports the natural width of the current label.
struct LabelLengthKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Draws one frame of the control, laid out horizontally from the leading edge.
///
/// The parent rotates it for vertical directions; `rotation` lets the renderer keep icons
/// upright and shadows falling down. `isMirrored` flips the geometry for right-to-left layouts
/// without mirroring any text.
struct SlideTrack: View {
    let snapshot: ConfirmSnapshot
    let layout: TrackLayout
    let configuration: SlideToConfirmConfiguration
    let palette: SlideToConfirmPalette
    let label: Text
    let font: Font
    let labelLength: CGFloat
    let textDirection: LayoutDirection
    let isMirrored: Bool
    let rotation: Angle
    let isAnimated: Bool
    let knobBuilder: SlideToConfirmKnobBuilder?
    let direction: SlideToConfirmDirection

    private var length: CGFloat { CGFloat(layout.length) }
    private var thickness: CGFloat { CGFloat(layout.thickness) }
    private var trackShape: TrackShape { TrackShape(cornerRadius: configuration.cornerRadius) }

    var body: some View {
        let isSuccess = snapshot.phase == .success
        let opacities = layout.labelOpacities(snapshot, textLength: Double(labelLength))

        ZStack(alignment: .topLeading) {
            trackShape.fill(isSuccess ? palette.success : palette.track)
            softFill
            solidFill
            baseLabel.opacity(opacities.base)
            revealLabel.opacity(snapshot.showsRevealLabel ? opacities.reveal : 0)
            knob
        }
        .frame(width: length, height: thickness, alignment: .topLeading)
        .clipShape(trackShape)
        .overlay(trackShape.strokeBorder(isSuccess ? Color.clear : palette.trackBorder, lineWidth: 1))
        .background(trackShadow(isSuccess: isSuccess))
        .background(labelMeasurement)
        .opacity(snapshot.isEnabled ? 1 : configuration.disabledOpacity)
    }

    // MARK: Fills

    private var softFill: some View {
        let reach = CGFloat(layout.softFillLength(progress: snapshot.progress))
        return trackShape
            .fill(snapshot.isArmed ? palette.armedFill : palette.fill)
            .frame(width: reach, height: thickness)
            .offset(x: isMirrored ? length - reach : 0)
            .opacity(snapshot.showsSoftFill ? 1 : 0)
    }

    private var solidFill: some View {
        let reach = CGFloat(layout.solidFillLength(snapshot))
        return TrackShape(cornerRadius: snapshot.isFollowing ? configuration.cornerRadius : 0)
            .fill(palette.solidFill)
            .frame(width: reach, height: thickness)
            .offset(x: isMirrored ? length - reach : 0)
            .opacity(snapshot.showsSolidFill ? 1 : 0)
    }

    // MARK: Labels

    private var styledLabel: Text {
        label.font(font).tracking(configuration.labelTracking)
    }

    private var baseLabel: some View {
        let insets = layout.baseLabelInsets(snapshot)
        return labelLayer(insets: insets) {
            if snapshot.isShimmering && configuration.shimmer && isAnimated {
                ShimmerText(
                    text: styledLabel,
                    color: palette.label,
                    dimmedColor: palette.dimmedLabel,
                    duration: configuration.shimmerDuration,
                    isReversed: isMirrored
                )
            } else {
                styledLabel.foregroundStyle(baseLabelColor)
            }
        }
    }

    private var baseLabelColor: Color {
        switch snapshot.phase {
        case .idle: return palette.label
        case .processing: return palette.onSolidFill
        case .success: return palette.onSuccess
        case .failure: return palette.failureLabel
        }
    }

    private var revealLabel: some View {
        let insets = layout.revealLabelInsets(snapshot)
        let reach = CGFloat(layout.solidFillLength(snapshot))
        return labelLayer(insets: insets) {
            styledLabel.foregroundStyle(palette.onSolidFill)
        }
        .mask(alignment: .topLeading) {
            if snapshot.isFollowing {
                Rectangle()
            } else {
                // Fill hold: the label changes color exactly where the fill has reached.
                Rectangle()
                    .frame(width: reach, height: thickness)
                    .offset(x: isMirrored ? length - reach : 0)
            }
        }
    }

    /// A full-track layer with `content` centered in the stretch between `insets`.
    private func labelLayer<Content: View>(
        insets: TrackLayout.Insets,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let leading = CGFloat(isMirrored ? insets.trailing : insets.leading)
        let width = max(0, length - CGFloat(insets.leading + insets.trailing))
        let clipsInsteadOfTruncating = snapshot.isFollowing && snapshot.phase == .idle
        return Color.clear
            .frame(width: length, height: thickness)
            .overlay(alignment: .topLeading) {
                Group {
                    if clipsInsteadOfTruncating {
                        content()
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(width: width, height: thickness)
                            .clipped()
                    } else {
                        content()
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .truncationMode(.tail)
                            .frame(width: width, height: thickness)
                    }
                }
                .multilineTextAlignment(.center)
                .environment(\.layoutDirection, textDirection)
                .offset(x: leading)
            }
            .allowsHitTesting(false)
    }

    /// Measures the label's natural width so a combined hold knows when to hand it over.
    private var labelMeasurement: some View {
        styledLabel
            .fixedSize()
            .hidden()
            .background(GeometryReader { proxy in
                Color.clear.preference(key: LabelLengthKey.self, value: proxy.size.width)
            })
            .environment(\.layoutDirection, textDirection)
    }

    // MARK: Knob

    private var knob: some View {
        let diameter = CGFloat(layout.knobDiameter)
        let leading = CGFloat(layout.knobLeading(progress: snapshot.progress))
        return KnobView(
            snapshot: snapshot,
            configuration: configuration,
            palette: palette,
            diameter: diameter,
            isMirrored: isMirrored,
            uprightRotation: -rotation,
            shadowOffset: rendererVector(for: palette.knobShadow),
            isAnimated: isAnimated,
            knobBuilder: knobBuilder,
            direction: direction
        )
        .frame(width: diameter, height: diameter)
        .scaleEffect(snapshot.isArmed ? configuration.armedKnobScale : 1)
        .animation(.easeOut(duration: 0.15), value: snapshot.isArmed)
        .offset(
            x: isMirrored ? length - leading - diameter : leading,
            y: CGFloat(layout.knobInset)
        )
    }

    // MARK: Shadow

    @ViewBuilder
    private func trackShadow(isSuccess: Bool) -> some View {
        if let shadow = palette.trackShadow, !isSuccess {
            let offset = rendererVector(for: shadow)
            trackShape
                .fill(palette.track)
                .shadow(color: shadow.color, radius: shadow.radius, x: offset.width, y: offset.height)
        }
    }

    /// Converts a shadow offset meant for the screen into this view's rotated space, so shadows
    /// fall the same way whatever the slide direction.
    private func rendererVector(for shadow: SlideToConfirmShadow?) -> CGSize {
        guard let shadow else { return .zero }
        let radians = -rotation.radians
        return CGSize(
            width: shadow.x * cos(radians) - shadow.y * sin(radians),
            height: shadow.x * sin(radians) + shadow.y * cos(radians)
        )
    }
}

/// The knob: its color, shadow, countdown ring and icon.
struct KnobView: View {
    let snapshot: ConfirmSnapshot
    let configuration: SlideToConfirmConfiguration
    let palette: SlideToConfirmPalette
    let diameter: CGFloat
    let isMirrored: Bool
    /// Undoes the parent's rotation, for icons that should stay upright.
    let uprightRotation: Angle
    let shadowOffset: CGSize
    let isAnimated: Bool
    let knobBuilder: SlideToConfirmKnobBuilder?
    let direction: SlideToConfirmDirection

    var body: some View {
        let isSuccess = snapshot.phase == .success
        let isInverted = snapshot.isKnobInverted
        let fillColor = isSuccess ? palette.onSuccess : (isInverted ? palette.onSolidFill : palette.knob)
        let iconColor = isSuccess ? palette.success : (isInverted ? palette.solidFill : palette.knobIcon)
        let shape = TrackShape(cornerRadius: configuration.cornerRadius.map { max(0, $0 - configuration.knobInset) })
        let icon = configuration.icons.icon(for: snapshot.knobIcon)

        ZStack {
            shape
                .fill(fillColor)
                .shadow(
                    color: isSuccess ? .clear : (palette.knobShadow?.color ?? .clear),
                    radius: palette.knobShadow?.radius ?? 0,
                    x: shadowOffset.width,
                    y: shadowOffset.height
                )
                .animation(.easeOut(duration: 0.25), value: isInverted)

            if snapshot.showsRing && configuration.showsHoldRing {
                ring(color: iconColor, trackColor: isInverted ? palette.invertedRingTrack : palette.ringTrack)
                    .rotationEffect(uprightRotation)
            }

            Group {
                if let knobBuilder {
                    knobBuilder.build(SlideToConfirmKnobContext(
                        state: snapshot.publicState,
                        iconColor: iconColor,
                        diameter: diameter,
                        direction: direction
                    ))
                    .rotationEffect(uprightRotation)
                } else {
                    KnobIconView(icon: icon, color: iconColor, size: diameter * 0.46, isAnimated: isAnimated)
                        .scaleEffect(x: icon.followsDirection && isMirrored ? -1 : 1, y: 1)
                        .rotationEffect(icon.followsDirection ? .zero : uprightRotation)
                }
            }
            .id(snapshot.knobIcon)
            .transition(.scale(scale: 0.6).combined(with: .opacity))
        }
    }

    private func ring(color: Color, trackColor: Color) -> some View {
        let lineWidth = configuration.ringLineWidth
        let inset = lineWidth / 2 + 2.25
        return ZStack {
            Circle()
                .inset(by: inset)
                .stroke(trackColor, lineWidth: lineWidth)
            Circle()
                .inset(by: inset)
                .trim(from: 0, to: CGFloat(snapshot.ringProgress))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
#endif
