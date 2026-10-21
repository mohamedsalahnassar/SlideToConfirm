import Foundation

/// Everything the view needs to draw one frame, resolved for a moment in time.
struct ConfirmSnapshot: Equatable {
    enum Label: Equatable {
        case idle, armed, holding, processing, success, failure
    }

    enum KnobIcon: Equatable {
        case idle, processing, success, failure
    }

    var phase: SlideToConfirmPhase
    var interaction: ConfirmEngine.Interaction
    var holdBehavior: SlideToConfirmHoldBehavior
    /// Knob position, 0...1.
    var progress: Double
    /// Solid fill for ``SlideToConfirmHoldBehavior/fill``, 0...1.
    var fillProgress: Double
    /// Countdown ring, 0...1.
    var ringProgress: Double
    var isArmed: Bool
    var isEnabled: Bool
    var failureMessage: String?

    var isHolding: Bool { interaction == .holding }
    var isDragging: Bool { interaction == .dragging }

    /// Combined hold: the solid fill follows the gliding knob.
    var isFollowing: Bool { isHolding && holdBehavior == .combined }

    /// Fill hold: the solid fill grows from the start edge while the knob stays put.
    var isFilling: Bool { holdBehavior == .fill && (fillProgress > 0 || isHolding) }

    var showsSoftFill: Bool { phase != .success && phase != .failure }

    var showsSolidFill: Bool {
        phase == .processing || ((isFollowing || isFilling) && phase != .success)
    }

    /// The label copy drawn on the solid fill is visible.
    var showsRevealLabel: Bool { showsSolidFill && phase == .idle }

    /// The knob swaps to the on-fill color so it stands out on the solid fill.
    var isKnobInverted: Bool {
        phase == .idle && (isFollowing || (isFilling && (isHolding || fillProgress > 0.02)))
    }

    /// The label moves to the stretch of track behind the knob.
    var labelSitsBehindKnob: Bool {
        isArmed || phase == .processing || phase == .success
            || (isHolding && holdBehavior == .glide && progress >= 0.45)
    }

    /// The idle label shimmers toward the end of the track.
    var isShimmering: Bool {
        phase == .idle && !isArmed && !isHolding && !isDragging && isEnabled
    }

    var showsRing: Bool { isHolding }

    var label: Label {
        switch phase {
        case .processing: return .processing
        case .success: return .success
        case .failure: return .failure
        case .idle:
            if isHolding { return .holding }
            if isArmed { return .armed }
            return .idle
        }
    }

    var knobIcon: KnobIcon {
        switch phase {
        case .idle: return .idle
        case .processing: return .processing
        case .success: return .success
        case .failure: return .failure
        }
    }

    var publicState: SlideToConfirmState {
        SlideToConfirmState(
            phase: phase,
            interaction: interaction.publicValue,
            progress: holdBehavior == .fill ? max(progress, fillProgress) : progress,
            isArmed: isArmed,
            isEnabled: isEnabled
        )
    }
}

/// The geometry of a track laid out horizontally, measured from the leading edge.
///
/// Vertical tracks reuse it: the view lays the track out horizontally and rotates it.
struct TrackLayout: Equatable {
    /// Insets of a label's region from the leading and trailing ends of the track.
    struct Insets: Equatable {
        var leading: Double
        var trailing: Double
    }

    var length: Double
    var thickness: Double
    var knobInset: Double
    var labelEdgePadding: Double = 20
    var labelKnobSpacing: Double = 6

    var knobDiameter: Double { max(0, thickness - 2 * knobInset) }

    /// How far the knob moves from start to end.
    var travel: Double { max(0, length - thickness) }

    func knobLeading(progress: Double) -> Double {
        knobInset + progress * travel
    }

    /// The soft fill reaches just past the far edge of the knob.
    func softFillLength(progress: Double) -> Double {
        thickness + progress * travel
    }

    func solidFillLength(_ snapshot: ConfirmSnapshot) -> Double {
        if snapshot.phase == .processing { return length }
        if snapshot.isFollowing { return softFillLength(progress: snapshot.progress) }
        if snapshot.isFilling { return snapshot.fillProgress * length }
        return 0
    }

    /// Where the label sits on the bare track.
    func baseLabelInsets(_ snapshot: ConfirmSnapshot) -> Insets {
        if snapshot.isFollowing && snapshot.phase == .idle {
            return Insets(leading: aheadOfKnob(snapshot.progress), trailing: labelEdgePadding)
        }
        return defaultInsets(snapshot)
    }

    /// Where the label copy drawn on the solid fill sits.
    func revealLabelInsets(_ snapshot: ConfirmSnapshot) -> Insets {
        if snapshot.isFollowing && snapshot.phase == .idle {
            return Insets(leading: labelEdgePadding, trailing: behindKnob(snapshot.progress))
        }
        return defaultInsets(snapshot)
    }

    /// Opacities of the base label and the label on the fill.
    ///
    /// While dragging, the label fades out of the knob's way. During a combined hold it rides
    /// ahead of the knob, then hands over to the copy on the fill once the copy fits behind it.
    func labelOpacities(_ snapshot: ConfirmSnapshot, textLength: Double) -> (base: Double, reveal: Double) {
        guard snapshot.phase == .idle else { return (1, 1) }
        let p = snapshot.progress
        var base = 1.0
        var reveal = 1.0

        let gliding = snapshot.isHolding && snapshot.holdBehavior == .glide
        if (snapshot.isDragging && !snapshot.isArmed) || gliding {
            base = gliding && p >= 0.45 ? min(1, (p - 0.45) * 8) : max(0, 1 - p * 2.4)
        }

        if snapshot.isFollowing {
            let travel = max(1, self.travel)
            let aheadMax = (length - thickness - labelEdgePadding - labelKnobSpacing - textLength) / travel
            let behindMin = (textLength + labelEdgePadding + 2) / travel
            let mid = (aheadMax + behindMin) / 2
            base = Self.clamp((min(aheadMax, mid + 0.035) - p) * 14)
            reveal = Self.clamp((p - max(behindMin, mid - 0.035)) * 14)
        }
        return (base, reveal)
    }

    private func defaultInsets(_ snapshot: ConfirmSnapshot) -> Insets {
        if snapshot.labelSitsBehindKnob {
            return Insets(leading: labelEdgePadding, trailing: behindKnob(snapshot.progress))
        }
        return Insets(leading: thickness + labelKnobSpacing, trailing: labelEdgePadding)
    }

    /// Leading inset of the stretch between the knob's far edge and the end.
    private func aheadOfKnob(_ progress: Double) -> Double {
        thickness + progress * travel + labelKnobSpacing
    }

    /// Trailing inset of the stretch between the start and the knob's near edge.
    private func behindKnob(_ progress: Double) -> Double {
        (1 - progress) * travel + thickness + labelKnobSpacing
    }

    private static func clamp(_ value: Double) -> Double { min(max(value, 0), 1) }
}
