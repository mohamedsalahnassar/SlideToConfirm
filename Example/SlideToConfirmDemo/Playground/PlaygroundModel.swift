import Observation
import SlideToConfirm
import SwiftUI

/// Every setting the Playground exposes, and the configuration and code they produce.
@Observable
final class PlaygroundModel {
    var surface: StageSurface = .light
    var language: DemoLanguage = .english
    var holdBehavior: SlideToConfirmHoldBehavior = .combined
    var direction: SlideToConfirmDirection = .trailing
    var allowsDragging = true
    var containerWidth: Double = 1100
    var maxLength: Double = 440
    var thickness: Double = 60
    var knobInset: Double = 4
    var isCapsule = true
    var cornerRadius: Double = 16
    var labelSize: Double = 15
    var holdDuration: Double = 1.2
    var holdDelay: Double = 0.18
    var commitThreshold: Double = 0.9
    var showsProcessing = true
    var simulatesFailure = false
    var shimmer = true
    var showsHoldRing = true
    var hapticsEnabled = true
    var theme: SlideToConfirmThemeChoice = .standard
    var customTint: Color = .orange
    var resetsAfterSuccess = true

    func reset() {
        let fresh = PlaygroundModel()
        surface = fresh.surface
        language = fresh.language
        holdBehavior = fresh.holdBehavior
        direction = fresh.direction
        allowsDragging = fresh.allowsDragging
        containerWidth = fresh.containerWidth
        maxLength = fresh.maxLength
        thickness = fresh.thickness
        knobInset = fresh.knobInset
        isCapsule = fresh.isCapsule
        cornerRadius = fresh.cornerRadius
        labelSize = fresh.labelSize
        holdDuration = fresh.holdDuration
        holdDelay = fresh.holdDelay
        commitThreshold = fresh.commitThreshold
        showsProcessing = fresh.showsProcessing
        simulatesFailure = fresh.simulatesFailure
        shimmer = fresh.shimmer
        showsHoldRing = fresh.showsHoldRing
        hapticsEnabled = fresh.hapticsEnabled
        theme = fresh.theme
        customTint = fresh.customTint
        resetsAfterSuccess = fresh.resetsAfterSuccess
    }

    var resolvedTheme: SlideToConfirmTheme {
        if surface == .brand { return .brand }
        switch theme {
        case .standard: return .standard
        case .brand: return .brand
        case .destructive: return .destructive
        case .positive: return .positive
        case .monochrome: return .monochrome
        case .custom: return .tinted(customTint)
        }
    }

    var configuration: SlideToConfirmConfiguration {
        SlideToConfirmConfiguration().with {
            $0.direction = direction
            $0.holdBehavior = holdBehavior
            $0.allowsDragging = allowsDragging
            $0.commitThreshold = commitThreshold
            $0.holdDuration = holdDuration
            $0.holdDelay = holdDelay
            $0.thickness = thickness
            $0.knobInset = knobInset
            $0.maxLength = maxLength
            $0.cornerRadius = isCapsule ? nil : cornerRadius
            $0.labelSize = labelSize
            $0.shimmer = shimmer
            $0.showsHoldRing = showsHoldRing
            $0.theme = resolvedTheme
            $0.successBehavior = resetsAfterSuccess ? .reset(after: 2) : .remain
            if direction.isVertical { $0.idealLength = 300 }
        }
    }

    /// Swift that reproduces the current settings, listing only what differs from the defaults.
    var code: String {
        var lines: [String] = []
        let defaults = SlideToConfirmConfiguration()
        func add(_ line: String) { lines.append("    $0.\(line)") }
        func number(_ value: Double, digits: Int = 0) -> String { String(format: "%.\(digits)f", value) }
        func differs(_ value: Double, _ base: Double) -> Bool { abs(value - base) > 0.0001 }

        if direction != defaults.direction { add("direction = .\(direction.rawValue)") }
        if holdBehavior != defaults.holdBehavior { add("holdBehavior = .\(holdBehavior.rawValue)") }
        if !allowsDragging { add("allowsDragging = false") }
        if differs(commitThreshold, defaults.commitThreshold) { add("commitThreshold = \(number(commitThreshold, digits: 2))") }
        if differs(holdDuration, defaults.holdDuration) { add("holdDuration = \(number(holdDuration, digits: 1))") }
        if differs(holdDelay, defaults.holdDelay) { add("holdDelay = \(number(holdDelay, digits: 2))") }
        if differs(thickness, Double(defaults.thickness)) { add("thickness = \(number(thickness))") }
        if differs(knobInset, Double(defaults.knobInset)) { add("knobInset = \(number(knobInset))") }
        if differs(maxLength, Double(defaults.maxLength ?? 0)) { add("maxLength = \(number(maxLength))") }
        if !isCapsule { add("cornerRadius = \(number(cornerRadius))") }
        if differs(labelSize, Double(defaults.labelSize)) { add("labelSize = \(number(labelSize))") }
        if !shimmer { add("shimmer = false") }
        if !showsHoldRing { add("showsHoldRing = false") }
        if resetsAfterSuccess { add("successBehavior = .reset(after: 2)") }
        if surface == .brand {
            add("theme = .brand")
        } else {
            switch theme {
            case .standard: break
            case .custom: add("theme = .tinted(.orange)")
            default: add("theme = .\(theme.rawValue)")
            }
        }

        var code = """
        SlideToConfirm("Slide or hold to send") {
            try await transfer.send()
        }
        """
        if !lines.isEmpty {
            code += "\n.slideToConfirmConfiguration {\n" + lines.joined(separator: "\n") + "\n}"
        }
        if !hapticsEnabled {
            code += "\n.slideToConfirmHaptics(.disabled)"
        }
        return code
    }
}
