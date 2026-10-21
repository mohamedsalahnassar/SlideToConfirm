import SlideToConfirm
import SwiftUI
import UIKit

/// Hosts a plain UIKit view controller that uses `SlideToConfirmControl`.
struct UIKitScenario: View {
    var body: some View {
        UIKitDemoRepresentable()
            .ignoresSafeArea(edges: .bottom)
            .background(DS.background.ignoresSafeArea())
            .navigationTitle("UIKit")
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct UIKitDemoRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIKitDemoViewController { UIKitDemoViewController() }
    func updateUIViewController(_ controller: UIKitDemoViewController, context: Context) {}
}

/// A UIKit screen built with Auto Layout: a confirm control, target-action and an event log.
final class UIKitDemoViewController: UIViewController {
    private let control = SlideToConfirmControl(
        labels: SlideToConfirmLabels(
            "Slide or hold to approve",
            armed: "Release to approve",
            holding: "Keep holding…",
            processing: "Approving…",
            success: "Approved"
        )
    )
    private let log = UILabel()
    private var events: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(DS.background)

        let title = UILabel()
        title.text = "Expense report #318"
        title.font = .systemFont(ofSize: 28, weight: .bold)
        title.textColor = UIColor(DS.ink)
        title.numberOfLines = 0

        let detail = UILabel()
        detail.text = "This screen is pure UIKit. SlideToConfirmControl is a UIControl: pin it with Auto Layout, set an async action, and listen for .primaryActionTriggered and .valueChanged."
        detail.font = .preferredFont(forTextStyle: .subheadline)
        detail.adjustsFontForContentSizeCategory = true
        detail.textColor = UIColor(DS.ink2)
        detail.numberOfLines = 0

        log.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        log.textColor = UIColor(DS.ink2)
        log.numberOfLines = 0
        log.text = "Events appear here."

        let logContainer = UIView()
        logContainer.backgroundColor = UIColor(DS.surface)
        logContainer.layer.cornerRadius = 16
        logContainer.layer.cornerCurve = .continuous
        logContainer.layer.borderWidth = 1
        logContainer.layer.borderColor = UIColor(DS.line).cgColor
        log.translatesAutoresizingMaskIntoConstraints = false
        logContainer.addSubview(log)

        let reset = UIButton(configuration: .gray(), primaryAction: UIAction(title: "Reset control") { [weak self] _ in
            self?.control.reset()
            self?.append("reset()")
        })

        control.configuration = .default.with {
            $0.theme = .positive
            $0.icons.idle = .systemImage("checkmark.seal.fill")
        }
        control.action = { [weak self] trigger in
            self?.append("action(\(trigger.rawValue)) started")
            try await Task.sleep(for: .seconds(1.2))
            self?.append("action finished")
        }
        control.addAction(UIAction { [weak self] _ in
            self?.append("primaryActionTriggered")
        }, for: .primaryActionTriggered)
        control.stateDidChange = { [weak self] state in
            guard state.interaction != .dragging, state.interaction != .holding else { return }
            self?.append("state → \(state.phase)")
        }
        control.accessibilityIdentifier = "uikit.control"

        let stack = UIStackView(arrangedSubviews: [title, detail, logContainer, UIView(), reset, control])
        stack.axis = .vertical
        stack.spacing = 16
        stack.setCustomSpacing(8, after: title)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            log.leadingAnchor.constraint(equalTo: logContainer.leadingAnchor, constant: 14),
            log.trailingAnchor.constraint(equalTo: logContainer.trailingAnchor, constant: -14),
            log.topAnchor.constraint(equalTo: logContainer.topAnchor, constant: 12),
            log.bottomAnchor.constraint(equalTo: logContainer.bottomAnchor, constant: -12),
        ])
    }

    private func append(_ event: String) {
        events.append(event)
        log.text = events.suffix(8).joined(separator: "\n")
    }
}
