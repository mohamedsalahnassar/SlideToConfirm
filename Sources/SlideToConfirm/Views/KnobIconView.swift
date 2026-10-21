#if canImport(SwiftUI)
import SwiftUI

/// Draws a ``SlideToConfirmIcon`` in a square of `size` points.
struct KnobIconView: View {
    let icon: SlideToConfirmIcon
    let color: Color
    let size: CGFloat
    /// `false` freezes the spinner and draws the check mark fully, for previews and snapshots.
    let isAnimated: Bool

    var body: some View {
        Group {
            switch icon {
            case .chevron:
                IconStroke(shape: ChevronShape(), lineWidth: 2.4, size: size)
            case .arrow:
                IconStroke(shape: ArrowShape(), lineWidth: 2.2, size: size)
            case .checkmark:
                CheckmarkIcon(size: size, isAnimated: isAnimated)
            case .exclamationmark:
                IconStroke(shape: ExclamationShape(), lineWidth: 2.4, size: size)
            case .spinner:
                SpinnerIcon(size: size, isAnimated: isAnimated)
            case let .systemImage(name, _):
                Image(systemName: name)
                    .font(.system(size: size * 0.74, weight: .bold))
                    .imageScale(.medium)
            case .none:
                Color.clear
            }
        }
        .foregroundStyle(color)
        .frame(width: size, height: size)
    }
}

private struct IconStroke<S: Shape>: View {
    let shape: S
    let lineWidth: CGFloat
    let size: CGFloat

    var body: some View {
        shape.stroke(style: StrokeStyle(lineWidth: lineWidth * size / 24, lineCap: .round, lineJoin: .round))
    }
}

private struct CheckmarkIcon: View {
    let size: CGFloat
    let isAnimated: Bool
    @State private var drawn: CGFloat = 0

    var body: some View {
        CheckmarkShape()
            .trim(from: 0, to: isAnimated ? drawn : 1)
            .stroke(style: StrokeStyle(lineWidth: 2.8 * size / 24, lineCap: .round, lineJoin: .round))
            .onAppear {
                guard isAnimated else { return }
                withAnimation(.easeOut(duration: 0.32).delay(0.06)) { drawn = 1 }
            }
    }
}

private struct SpinnerIcon: View {
    let size: CGFloat
    let isAnimated: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !isAnimated)) { context in
            let turns = isAnimated ? context.date.timeIntervalSinceReferenceDate / 0.8 : 0.1
            SpinnerShape()
                .stroke(style: StrokeStyle(lineWidth: 2.6 * size / 24, lineCap: .round))
                .rotationEffect(.degrees((turns - turns.rounded(.down)) * 360))
        }
    }
}

// MARK: - Shapes, drawn on a 24 × 24 grid

private extension Path {
    /// Maps a point on the 24 × 24 design grid into `rect`.
    static func grid(_ rect: CGRect, _ build: (inout Path, (CGFloat, CGFloat) -> CGPoint) -> Void) -> Path {
        let side = min(rect.width, rect.height)
        let scale = side / 24
        let origin = CGPoint(x: rect.midX - side / 2, y: rect.midY - side / 2)
        var path = Path()
        build(&path) { CGPoint(x: origin.x + $0 * scale, y: origin.y + $1 * scale) }
        return path
    }
}

struct ChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        .grid(rect) { path, p in
            path.move(to: p(9.5, 5.5))
            path.addLine(to: p(16, 12))
            path.addLine(to: p(9.5, 18.5))
        }
    }
}

struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        .grid(rect) { path, p in
            path.move(to: p(4.5, 12))
            path.addLine(to: p(19, 12))
            path.move(to: p(13, 6))
            path.addLine(to: p(19, 12))
            path.addLine(to: p(13, 18))
        }
    }
}

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        .grid(rect) { path, p in
            path.move(to: p(5, 12.5))
            path.addLine(to: p(9.5, 17))
            path.addLine(to: p(19, 7.5))
        }
    }
}

struct ExclamationShape: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        var path = Path.grid(rect) { path, p in
            path.move(to: p(12, 7.5))
            path.addLine(to: p(12, 12.5))
            path.move(to: p(12, 16.5))
            path.addLine(to: p(12, 16.51))
        }
        path.addEllipse(in: CGRect(
            x: rect.midX - side * 8.5 / 24,
            y: rect.midY - side * 8.5 / 24,
            width: side * 17 / 24,
            height: side * 17 / 24
        ))
        return path
    }
}

struct SpinnerShape: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: side * 8.5 / 24,
            startAngle: .degrees(-90),
            endAngle: .degrees(180),
            clockwise: false
        )
        return path
    }
}

/// A capsule, or a rounded rectangle when `cornerRadius` is set.
struct TrackShape: InsettableShape {
    var cornerRadius: CGFloat?
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let rect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        guard rect.width > 0, rect.height > 0 else { return Path() }
        if let cornerRadius {
            let radius = min(max(0, cornerRadius - insetAmount), min(rect.width, rect.height) / 2)
            return RoundedRectangle(cornerRadius: radius, style: .continuous).path(in: rect)
        }
        return Capsule(style: .circular).path(in: rect)
    }

    func inset(by amount: CGFloat) -> TrackShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}

/// Shakes horizontally once per whole-number step of `animatableData`.
struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    private static let keyframes: [(time: CGFloat, offset: CGFloat)] = [
        (0, 0), (0.2, -7), (0.4, 6), (0.6, -4), (0.8, 2), (1, 0),
    ]

    func effectValue(size: CGSize) -> ProjectionTransform {
        let t = animatableData - animatableData.rounded(.down)
        guard t > 0 else { return ProjectionTransform() }
        var offset: CGFloat = 0
        for (start, end) in zip(Self.keyframes, Self.keyframes.dropFirst()) where t >= start.time && t <= end.time {
            let local = (t - start.time) / (end.time - start.time)
            offset = start.offset + (end.offset - start.offset) * local
            break
        }
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

/// Redraws densely only while the shimmer highlight crosses the label, and idles in between.
struct ShimmerSchedule: TimelineSchedule {
    var period: TimeInterval
    /// The part of each period, from 0 to 1, when the highlight is over the label.
    var activeWindow: ClosedRange<Double> = 0.33...0.67
    var frameInterval: TimeInterval = 1.0 / 60

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        let period = max(0.1, self.period)
        let window = activeWindow
        let step = mode == .lowFrequency ? period : frameInterval
        var time = startDate.timeIntervalSinceReferenceDate
        return AnyIterator {
            let current = time
            let cycleStart = (current / period).rounded(.down) * period
            let phase = (current - cycleStart) / period
            if phase < window.lowerBound {
                time = cycleStart + window.lowerBound * period
            } else if phase <= window.upperBound {
                time = current + step
            } else {
                time = cycleStart + period + window.lowerBound * period
            }
            return Date(timeIntervalSinceReferenceDate: current)
        }
    }
}

/// A label whose highlight sweeps toward the end of the track.
struct ShimmerText: View {
    let text: Text
    let color: Color
    let dimmedColor: Color
    let duration: TimeInterval
    let isReversed: Bool

    var body: some View {
        TimelineView(ShimmerSchedule(period: duration)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let t = (time / duration) - (time / duration).rounded(.down)
            // The highlight's center travels from 2.5 widths before the label to 2.5 widths past it.
            let center = isReversed ? 3.5 - 6 * t : -2.5 + 6 * t
            text.foregroundStyle(
                LinearGradient(
                    stops: [
                        .init(color: dimmedColor, location: 0),
                        .init(color: dimmedColor, location: 0.35),
                        .init(color: color, location: 0.5),
                        .init(color: dimmedColor, location: 0.65),
                        .init(color: dimmedColor, location: 1),
                    ],
                    startPoint: UnitPoint(x: center - 1.5, y: 0.5),
                    endPoint: UnitPoint(x: center + 1.5, y: 0.5)
                )
            )
        }
    }
}
#endif
