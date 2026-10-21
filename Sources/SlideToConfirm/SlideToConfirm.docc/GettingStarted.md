# Getting started

Add a confirm control to a screen, run an async action and react to the outcome.

## Add the package

In Xcode choose **File › Add Package Dependencies…** and enter
`https://github.com/mohamedsalahnassar/SlideToConfirm`, or add it to `Package.swift`:

```swift
.package(url: "https://github.com/mohamedsalahnassar/SlideToConfirm", from: "1.0.0")
```

## Place the control

Pin the control to the bottom of a task screen, where the thumb rests:

```swift
struct ReviewTransferView: View {
    let transfer: Transfer

    var body: some View {
        ScrollView { TransferDetails(transfer: transfer) }
            .safeAreaInset(edge: .bottom) {
                SlideToConfirm("Slide or hold to send") {
                    try await transfer.send()
                }
                .padding()
            }
    }
}
```

On iPhone the control fills the width inside the margins. On iPad and Mac it stops growing at
440 pt and stays centered.

## Handle the outcome

The control shows **processing** while your action runs and **success** when it returns.
If the action throws, it shows **failure**, shakes, plays the error haptic and returns to idle.

```swift
SlideToConfirm("Slide to pay") {
    guard wallet.balance >= amount else {
        throw SlideToConfirmFailure("Insufficient funds")   // shown on the control
    }
    try await wallet.pay(amount)
}
```

Throw `CancellationError` to return to idle quietly. By default the control stays in success so it
can't fire twice; choose ``SlideToConfirmSuccessBehavior/reset(after:)`` to make it reusable.

## Label every state

```swift
SlideToConfirm(labels: SlideToConfirmLabels(
    "Slide or hold to send",
    armed: "Release to send",
    holding: "Keep holding…",
    processing: "Sending…",
    success: "Sent",
    failure: "Not sent · try again"
)) {
    try await transfer.send()
}
```

## Learn how it was confirmed

```swift
SlideToConfirm("Slide or hold to send") { trigger in
    analytics.log("confirm", method: trigger.rawValue)   // drag, hold, holdThenDrag, keyboard, accessibility
    try await transfer.send()
}
```
