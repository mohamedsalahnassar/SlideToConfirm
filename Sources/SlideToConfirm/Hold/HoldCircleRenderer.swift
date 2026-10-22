#if canImport(SwiftUI)
import SwiftUI

/// Reports the natural width of the success label, for the morph completion.
struct MorphLabelWidthKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Draws one frame of a ``HoldToConfirmButton``: the circle, its progress style and its
/// completion effect.
///
/// `celebration` runs from 0 to 1 when the action succeeds and is animatable, so every
/// completion style is a pure function of it. That keeps effects deterministic for snapshots.
struct HoldCircleRenderer: View, Animatable {
    var celebration: CGFloat
    let snapshot: ConfirmSnapshot
    let configuration: HoldToConfirmConfiguration
    let palette: SlideToConfirmPalette
    let successLabel: Text
    let labelFont: Font
    let morphLabelWidth: CGFloat
    /// `false` freezes time-driven motion: previews, snapshots and Reduce Motion.
    let isAnimated: Bool

    var animatableData: CGFloat {
        get { celebration }
        set { celebration = newValue }
    }

    private var diameter: CGFloat { configuration.diameter }
    private var outer: CGFloat { configuration.outerDiameter }
    private var style: HoldToConfirmProgressStyle { configuration.progressStyle }
    private var completion: HoldToConfirmCompletionStyle { configuration.completionStyle }

    /// Hold progress, 0...1. A tap's nudge never shows as progress.
    private var progress: CGFloat {
        let value: Double
        if snapshot.holdBehavior == .fill {
            // The knob position only moves for a nudge or a keyboard activation; show the latter.
            value = snapshot.progress >= 1 ? 1 : snapshot.fillProgress
        } else {
            value = snapshot.interaction == .nudging ? 0 : snapshot.progress
        }
        return CGFloat(min(max(value, 0), 1))
    }

    private var isPressed: Bool {
        snapshot.phase == .idle && (snapshot.interaction == .pending || snapshot.interaction == .holding)
    }

    /// The flip completion shows the processing face until it turns past halfway.
    private var showsSuccessFace: Bool {
        snapshot.phase == .success && (completion != .flip || celebration >= 0.5)
    }

    var body: some View {
        ZStack {
            if style == .glow { glow }
            if style == .pulse, snapshot.phase == .idle, snapshot.isHolding { pulse }
            if style.drawsRing || snapshot.phase == .processing { ring }
            disk
            if snapshot.phase == .success { celebrationEffects }
        }
        .frame(width: outer, height: outer)
        .opacity(snapshot.isEnabled ? 1 : configuration.disabledOpacity)
        .background(morphLabelMeasurement)
    }

    // MARK: Disk

    private var disk: some View {
        let width = diskWidth
        return ZStack {
            Capsule(style: .circular).fill(diskColor)
            diskContent
            if style.fillsCircle, snapshot.phase == .idle, !showsSuccessFace {
                Capsule(style: .circular).strokeBorder(palette.trackBorder, lineWidth: 1)
                // Over the icon, with its own copy of the icon on the fill.
                fillLayer
            }
        }
        .frame(width: width, height: diameter)
        .shadow(
            color: configuration.showsShadow && snapshot.phase != .success ? (palette.knobShadow?.color ?? .clear) : .clear,
            radius: palette.knobShadow?.radius ?? 0,
            x: palette.knobShadow?.x ?? 0,
            y: palette.knobShadow?.y ?? 0
        )
        .scaleEffect(diskScale)
        .animation(.spring(response: 0.28, dampingFraction: 0.62), value: isPressed)
        .animation(.spring(response: 0.22, dampingFraction: 0.45), value: snapshot.interaction == .nudging)
        .rotation3DEffect(
            .degrees(completion == .flip && snapshot.phase == .success ? Double(celebration) * 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
    }

    private var diskWidth: CGFloat {
        guard completion == .morph, snapshot.phase == .success, morphLabelWidth > 0 else { return diameter }
        return diameter + (morphLabelWidth + diameter * 0.2) * celebration
    }

    private var diskScale: CGFloat {
        var scale: CGFloat = 1
        if isPressed { scale *= configuration.pressedScale }
        if snapshot.interaction == .nudging { scale *= 1.06 }
        if completion == .bounce, snapshot.phase == .success {
            scale *= 1 + 0.2 * sin(.pi * min(max(celebration, 0), 1))
        }
        return scale
    }

    private var diskColor: Color {
        switch snapshot.phase {
        case .success: return showsSuccessFace ? palette.success : palette.solidFill
        case .failure: return palette.failureLabel
        case .processing: return palette.solidFill
        case .idle: return style.fillsCircle ? tintedDisk : palette.knob
        }
    }

    /// A soft tint of the accent over the track, for styles that fill the circle.
    private var tintedDisk: Color { palette.armedFill }

    private var iconColor: Color {
        switch snapshot.phase {
        case .success: return showsSuccessFace ? palette.onSuccess : palette.onSolidFill
        case .failure: return palette.onSuccess
        case .processing: return palette.onSolidFill
        case .idle: return style.fillsCircle ? palette.knob : palette.knobIcon
        }
    }

    @ViewBuilder
    private var diskContent: some View {
        if completion == .morph, snapshot.phase == .success {
            HStack(spacing: 8 * celebration) {
                KnobIconView(icon: configuration.icons.success, color: palette.onSuccess, size: iconSize, isAnimated: isAnimated)
                successLabel
                    .font(labelFont)
                    .foregroundStyle(palette.onSuccess)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(width: morphLabelWidth * celebration, alignment: .leading)
                    .clipped()
                    .opacity(Double(celebration))
            }
        } else if completion == .flip, snapshot.phase == .success, !showsSuccessFace {
            KnobIconView(icon: configuration.icons.processing, color: palette.onSolidFill, size: iconSize, isAnimated: isAnimated)
        } else if style == .countdown, snapshot.phase == .idle, snapshot.isHolding || snapshot.interaction == .pending {
            countdownDigits(color: iconColor)
        } else {
            icon(color: iconColor)
                .scaleEffect(x: completion == .flip && snapshot.phase == .success ? -1 : 1, y: 1)
        }
    }

    private var iconSize: CGFloat { diameter * configuration.iconScale }

    private func icon(color: Color) -> some View {
        KnobIconView(
            icon: configuration.icons.icon(for: snapshot.knobIcon),
            color: color,
            size: iconSize,
            isAnimated: isAnimated
        )
        .id(snapshot.knobIcon)
        .transition(.scale(scale: 0.5).combined(with: .opacity))
    }

    private func countdownDigits(color: Color) -> some View {
        let remaining = max(1, Int((Double(1 - progress) * configuration.holdDuration).rounded(.up)))
        return Text(verbatim: "\(remaining)")
            .font(.system(size: diameter * 0.4, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(color)
            .id(remaining)
            .transition(.scale(scale: 1.4).combined(with: .opacity))
            .animation(.easeOut(duration: 0.2), value: remaining)
    }

    // MARK: Fill styles

    @ViewBuilder
    private var fillLayer: some View {
        if style == .liquid && isAnimated {
            TimelineView(.animation(minimumInterval: nil, paused: progress == 0)) { context in
                fill(shape: fillShape(phase: CGFloat(context.date.timeIntervalSinceReferenceDate)))
            }
        } else {
            fill(shape: fillShape(phase: 0.6))
        }
    }

    private func fill(shape: AnyShape) -> some View {
        ZStack {
            shape.fill(palette.solidFill)
            // The icon changes color exactly where the fill has reached.
            icon(color: palette.onSolidFill).mask { shape }
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .allowsHitTesting(false)
    }

    private func fillShape(phase: CGFloat) -> AnyShape {
        switch style {
        case .liquid: return AnyShape(WaveFillShape(progress: progress, phase: phase, amplitude: diameter * 0.045))
        case .radial: return AnyShape(RadialFillShape(progress: progress))
        case .pie: return AnyShape(PieFillShape(progress: progress))
        default: return AnyShape(WaveFillShape(progress: progress, phase: 0, amplitude: 0))
        }
    }

    // MARK: Ring styles

    private var ringDiameter: CGFloat { diameter + 2 * configuration.ringGap + configuration.ringWidth }

    private var ringLineWidth: CGFloat {
        style == .pulse ? max(1.5, configuration.ringWidth * 0.5) : configuration.ringWidth
    }

    @ViewBuilder
    private var ring: some View {
        let lineWidth = ringLineWidth
        ZStack {
            if snapshot.phase == .idle || snapshot.phase == .processing {
                Circle().stroke(palette.fill, lineWidth: lineWidth)
            }
            switch snapshot.phase {
            case .processing:
                spinnerArc(lineWidth: lineWidth)
            case .idle:
                ringProgress(lineWidth: lineWidth)
            case .success, .failure:
                EmptyView()
            }
        }
        .frame(width: ringDiameter, height: ringDiameter)
    }

    @ViewBuilder
    private func ringProgress(lineWidth: CGFloat) -> some View {
        switch style {
        case .segments:
            SegmentedRing(
                count: max(2, configuration.segmentCount),
                progress: progress,
                lineWidth: lineWidth,
                lit: palette.solidFill
            )
        case .orbit:
            OrbitRing(progress: progress, lineWidth: lineWidth, color: palette.solidFill)
        default:
            Circle()
                .trim(from: 0, to: progress)
                .stroke(palette.solidFill, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }

    private func spinnerArc(lineWidth: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: nil, paused: !isAnimated)) { context in
            let turns = isAnimated ? context.date.timeIntervalSinceReferenceDate / 0.9 : 0.15
            Circle()
                .trim(from: 0, to: 0.28)
                .stroke(palette.solidFill, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees((turns - turns.rounded(.down)) * 360 - 90))
        }
    }

    // MARK: Glow and pulse

    private var glow: some View {
        let active = snapshot.phase == .processing || (snapshot.phase == .idle && progress > 0)
        let level = snapshot.phase == .processing ? 1 : progress
        return Circle()
            .fill(palette.solidFill)
            .frame(width: diameter, height: diameter)
            .scaleEffect(1 + 0.32 * level)
            .blur(radius: 6 + 16 * level)
            .opacity(active ? Double(0.2 + 0.6 * level) : 0)
            .allowsHitTesting(false)
    }

    private var pulse: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !isAnimated)) { context in
            let time = isAnimated ? context.date.timeIntervalSinceReferenceDate : 0.4
            // Ripples come faster as the hold nears its end.
            let rate = 1 / (0.95 - 0.6 * Double(progress))
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    let raw = time * rate + Double(index) / 3
                    let phase = CGFloat(raw - raw.rounded(.down))
                    Circle()
                        .stroke(palette.solidFill, lineWidth: 2)
                        .frame(width: diameter + phase * (outer - diameter + 36), height: diameter + phase * (outer - diameter + 36))
                        .opacity(Double((1 - phase) * 0.55))
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: Completion

    @ViewBuilder
    private var celebrationEffects: some View {
        switch completion {
        case .ripple:
            let t = min(max(celebration, 0), 1)
            ZStack {
                Circle()
                    .stroke(palette.success, lineWidth: 1 + 4 * (1 - t))
                    .frame(width: diameter + t * (outer - diameter + 64), height: diameter + t * (outer - diameter + 64))
                    .opacity(Double(1 - t))
                Circle()
                    .stroke(palette.success.opacity(0.5), lineWidth: 1 + 2 * (1 - t))
                    .frame(width: diameter + t * (outer - diameter + 30), height: diameter + t * (outer - diameter + 30))
                    .opacity(Double(1 - t))
            }
            .allowsHitTesting(false)
        case .burst:
            BurstParticles(
                progress: min(max(celebration, 0), 1),
                radius: diameter / 2,
                colors: [palette.success, palette.solidFill, palette.success.opacity(0.7)]
            )
            .allowsHitTesting(false)
        case .checkmark, .bounce, .morph, .flip:
            EmptyView()
        }
    }

    private var morphLabelMeasurement: some View {
        successLabel
            .font(labelFont)
            .fixedSize()
            .hidden()
            .background(GeometryReader { proxy in
                Color.clear.preference(key: MorphLabelWidthKey.self, value: proxy.size.width)
            })
            .accessibilityHidden(true)
    }
}

// MARK: - Shapes and effects

/// The circle filled from the bottom up to `progress`, with an optional wave on the surface.
struct WaveFillShape: Shape {
    var progress: CGFloat
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard progress > 0 else { return Path() }
        let level = rect.maxY - rect.height * min(progress, 1)
        // Calm at the very start and end, liveliest halfway.
        let swell = amplitude * min(1, 4 * progress * (1 - progress) + 0.15)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        let steps = 24
        for step in 0...steps {
            let x = rect.minX + rect.width * CGFloat(step) / CGFloat(steps)
            let angle = (CGFloat(step) / CGFloat(steps)) * .pi * 2 * 1.2 + phase * 4
            path.addLine(to: CGPoint(x: x, y: level + sin(angle) * swell))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// A disc grown from the center to `progress` of the radius.
struct RadialFillShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2 * min(max(progress, 0), 1)
        return Path(ellipseIn: CGRect(x: rect.midX - radius, y: rect.midY - radius, width: radius * 2, height: radius * 2))
    }
}

/// A sector from twelve o'clock sweeping clockwise to `progress` of a turn.
struct PieFillShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard progress > 0 else { return Path() }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = max(rect.width, rect.height)
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * Double(min(progress, 1))),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

/// A ring of ticks that light up one by one.
private struct SegmentedRing: View {
    let count: Int
    let progress: CGFloat
    let lineWidth: CGFloat
    let lit: Color

    var body: some View {
        let gap: CGFloat = 0.018
        let span = 1 / CGFloat(count)
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                let start = CGFloat(index) * span
                let fraction = min(max((progress - start) / span, 0), 1)
                Circle()
                    .trim(from: start + gap, to: start + span - gap)
                    .stroke(lit, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    .opacity(Double(fraction))
            }
        }
        .rotationEffect(.degrees(-90))
    }
}

/// A comet riding the ring, its tail growing with progress.
private struct OrbitRing: View {
    let progress: CGFloat
    let lineWidth: CGFloat
    let color: Color

    var body: some View {
        let tail = min(progress, 0.3)
        GeometryReader { proxy in
            let radius = min(proxy.size.width, proxy.size.height) / 2
            let angle = Angle.degrees(Double(progress) * 360 - 90)
            ZStack {
                Circle()
                    .trim(from: progress - tail, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [color.opacity(0), color]),
                            center: .center,
                            startAngle: .degrees(Double(progress - tail) * 360),
                            endAngle: .degrees(Double(progress) * 360)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Circle()
                    .fill(color)
                    .frame(width: lineWidth * 2.2, height: lineWidth * 2.2)
                    .position(
                        x: proxy.size.width / 2 + radius * CGFloat(cos(angle.radians)),
                        y: proxy.size.height / 2 + radius * CGFloat(sin(angle.radians))
                    )
                    .opacity(progress > 0 ? 1 : 0)
            }
        }
    }
}

/// Particles flying outward and fading, a pure function of `progress`.
private struct BurstParticles: View {
    let progress: CGFloat
    let radius: CGFloat
    let colors: [Color]

    var body: some View {
        ZStack {
            ForEach(0..<14, id: \.self) { index in
                let angle = Double(index) / 14 * 2 * .pi + (index.isMultiple(of: 2) ? 0 : 0.18)
                let reach = radius + 8 + progress * (index.isMultiple(of: 2) ? 42 : 28)
                let size = (index.isMultiple(of: 2) ? 7 : 5) * (1 - progress * 0.6)
                Circle()
                    .fill(colors[index % colors.count])
                    .frame(width: size, height: size)
                    .offset(x: CGFloat(cos(angle)) * reach, y: CGFloat(sin(angle)) * reach)
                    .opacity(Double(1 - progress * progress))
            }
        }
    }
}
#endif
