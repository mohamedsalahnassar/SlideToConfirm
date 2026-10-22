#if canImport(UIKit) && canImport(SwiftUI) && !os(watchOS)
import SwiftUI
import UIKit

/// ``HoldToConfirmButton`` for UIKit.
///
/// ```swift
/// let control = HoldToConfirmControl(title: "Hold to send", systemImage: "paperplane.fill")
/// control.action = { trigger in
///     try await transfer.send()
/// }
/// view.addSubview(control)
/// ```
///
/// The control sends `.primaryActionTriggered` when it commits, before `action` runs, and
/// `.valueChanged` whenever ``confirmationState`` changes. It sizes itself: the circle, its ring
/// and its label make its intrinsic content size.
@MainActor
open class HoldToConfirmControl: UIControl {

    /// The text for each state.
    public var labels: SlideToConfirmLabels {
        didSet { refresh() }
    }

    /// The SF Symbol in the circle. `nil` uses the configured idle icon.
    public var systemImage: String? {
        didSet { refresh() }
    }

    /// Every adjustable aspect of the control.
    public var configuration: HoldToConfirmConfiguration {
        didSet {
            refresh()
            invalidateIntrinsicContentSize()
        }
    }

    /// How the control plays haptics. Default ``SlideToConfirmHaptics/automatic``.
    public var haptics: SlideToConfirmHaptics = .automatic {
        didSet { refresh() }
    }

    /// Freezes the control in a state, for galleries and snapshot tests. `nil` makes it live.
    public var previewState: HoldToConfirmPreviewState? {
        didSet { refresh() }
    }

    /// Runs on confirm. The control shows processing until it returns, then success. Throw to show
    /// failure. When `nil`, the control succeeds straight away.
    public var action: (@MainActor (SlideToConfirmTrigger) async throws -> Void)?

    /// Called whenever ``confirmationState`` changes, including every frame of progress.
    public var confirmationStateDidChange: (@MainActor (SlideToConfirmState) -> Void)?

    /// The control's current state.
    public private(set) var confirmationState: SlideToConfirmState = .idle

    /// The trigger of the most recent confirmation.
    public private(set) var lastTrigger: SlideToConfirmTrigger?

    open override var isEnabled: Bool {
        didSet { refresh() }
    }

    private let host = UIHostingController(rootView: AnyView(EmptyView()))
    private var generation = 0
    private var hostedSize: CGSize = .zero

    // MARK: Initializers

    /// Creates a control with labels for every state and an optional SF Symbol.
    public init(
        labels: SlideToConfirmLabels,
        systemImage: String? = nil,
        configuration: HoldToConfirmConfiguration = .default
    ) {
        self.labels = labels
        self.systemImage = systemImage
        self.configuration = configuration
        super.init(frame: .zero)
        setUp()
    }

    /// Creates a control with a verbatim idle label and built-in labels for the other states.
    public convenience init(
        title: String,
        systemImage: String? = nil,
        configuration: HoldToConfirmConfiguration = .default
    ) {
        self.init(labels: SlideToConfirmLabels(idle: Text(title)), systemImage: systemImage, configuration: configuration)
    }

    public required init?(coder: NSCoder) {
        self.labels = SlideToConfirmLabels(idle: Text("Press and hold", bundle: .module))
        self.systemImage = nil
        self.configuration = .default
        super.init(coder: coder)
        setUp()
    }

    // MARK: Public

    /// Returns the control to idle from any state, for example after success to allow another confirmation.
    public func reset() {
        generation += 1
        refresh()
    }

    // MARK: Layout

    open override var intrinsicContentSize: CGSize {
        host.sizeThatFits(in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        let size = intrinsicContentSize
        if size != hostedSize {
            hostedSize = size
            invalidateIntrinsicContentSize()
        }
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            invalidateIntrinsicContentSize()
        }
    }

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil, host.parent == nil, let parent = nearestViewController {
            parent.addChild(host)
            host.didMove(toParent: parent)
        } else if window == nil, host.parent != nil {
            host.willMove(toParent: nil)
            host.removeFromParent()
        }
    }

    // MARK: Private

    private func setUp() {
        backgroundColor = .clear
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 16.4, *) {
            host.safeAreaRegions = []
        }
        addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            host.view.topAnchor.constraint(equalTo: topAnchor),
            host.view.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        refresh()
    }

    private func refresh() {
        host.rootView = AnyView(
            HoldToConfirmButton(labels: labels, systemImage: systemImage) { [weak self] trigger in
                guard let self else { return }
                self.lastTrigger = trigger
                self.sendActions(for: .primaryActionTriggered)
                try await self.action?(trigger)
            }
            .holdToConfirmConfiguration(configuration)
            .slideToConfirmHaptics(haptics)
            .holdToConfirmPreviewState(previewState)
            .onHoldToConfirmStateChange { [weak self] state in
                self?.update(state)
            }
            .disabled(!isEnabled)
            .id(generation)
        )
    }

    private func update(_ newState: SlideToConfirmState) {
        guard newState != confirmationState else { return }
        confirmationState = newState
        confirmationStateDidChange?(newState)
        sendActions(for: .valueChanged)
    }

    private var nearestViewController: UIViewController? {
        var responder: UIResponder? = next
        while let current = responder {
            if let controller = current as? UIViewController { return controller }
            responder = current.next
        }
        return nil
    }
}
#endif
