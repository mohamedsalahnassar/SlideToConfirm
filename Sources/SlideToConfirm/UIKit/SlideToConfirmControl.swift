#if canImport(UIKit) && canImport(SwiftUI) && !os(watchOS)
import SwiftUI
import UIKit

/// ``SlideToConfirm`` for UIKit.
///
/// ```swift
/// let control = SlideToConfirmControl(title: "Slide or hold to send")
/// control.action = { trigger in
///     try await transfer.send()
/// }
/// view.addSubview(control)
/// ```
///
/// The control sends `.primaryActionTriggered` when it commits, before `action` runs, and
/// `.valueChanged` whenever ``confirmationState`` changes. Size it with Auto Layout: it has an intrinsic
/// height (or width, for vertical directions) and stretches along its direction up to
/// ``SlideToConfirmConfiguration/maxLength``, centered.
@MainActor
open class SlideToConfirmControl: UIControl {

    /// The text for each state.
    public var labels: SlideToConfirmLabels {
        didSet { refresh() }
    }

    /// Every adjustable aspect of the control.
    public var configuration: SlideToConfirmConfiguration {
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
    public var previewState: SlideToConfirmPreviewState? {
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

    /// Creates a control with labels for every state.
    public init(labels: SlideToConfirmLabels, configuration: SlideToConfirmConfiguration = .default) {
        self.labels = labels
        self.configuration = configuration
        super.init(frame: .zero)
        setUp()
    }

    /// Creates a control with a verbatim idle label and built-in labels for the other states.
    public convenience init(title: String, configuration: SlideToConfirmConfiguration = .default) {
        self.init(labels: SlideToConfirmLabels(idle: Text(title)), configuration: configuration)
    }

    public required init?(coder: NSCoder) {
        self.labels = SlideToConfirmLabels(idle: Text("Slide or hold to confirm", bundle: .module))
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
        let size = host.sizeThatFits(in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
        if configuration.direction.isVertical {
            return CGSize(width: size.width, height: UIView.noIntrinsicMetric)
        }
        return CGSize(width: UIView.noIntrinsicMetric, height: size.height)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        let size = host.sizeThatFits(in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
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
            SlideToConfirm(labels: labels) { [weak self] trigger in
                guard let self else { return }
                self.lastTrigger = trigger
                self.sendActions(for: .primaryActionTriggered)
                try await self.action?(trigger)
            }
            .slideToConfirmConfiguration(configuration)
            .slideToConfirmHaptics(haptics)
            .slideToConfirmPreviewState(previewState)
            .onSlideToConfirmStateChange { [weak self] state in
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
