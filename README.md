<div align="center">

<img src="Example/SlideToConfirmDemo/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="112" alt="SlideToConfirm icon">

# SlideToConfirm

**A confirm control you can slide, or simply hold.**<br>
For SwiftUI and UIKit · fully customizable · accessible · right-to-left ready

[![CI](https://github.com/mohamedsalahnassar/SlideToConfirm/actions/workflows/ci.yml/badge.svg)](https://github.com/mohamedsalahnassar/SlideToConfirm/actions/workflows/ci.yml)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2016%20%7C%20iPadOS%2016%20%7C%20macOS%2013-2343D6)](#requirements)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-1A7F45)](#installation)
[![License: MIT](https://img.shields.io/badge/license-MIT-555D74)](LICENSE)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-dark.gif">
  <img src="docs/images/demo-light.gif" width="560" alt="Holding the pill makes the knob glide and the track fill; dragging the knob past 90% confirms; letting go early springs back.">
</picture>

</div>

---

Consequential actions, such as sending money, deleting an account or unlocking a door, deserve a
gesture that can't happen by accident but stays effortless on purpose. **SlideToConfirm** gives
people two ways to say yes:

- **Slide** the knob past 90% of the track and let go.
- **Press and hold** anywhere on the pill. After 180 ms the knob glides to the end by itself and the
  track fills in behind it. Lift early and it springs back.

Both paths commit at the same point, play the same haptics and land in the same states:
**processing** while your async action runs, then **success**, or **failure** with a shake and a reason.

```swift
SlideToConfirm("Slide or hold to send") {
    try await transfer.send()
}
```

Short on room? **[`HoldToConfirmButton`](#hold-to-confirm-the-circle)** is the same engine as a
circle you press and hold, with ten progress styles, six completion styles, placements chosen for
thumb reach and a ring that fits a 56 pt side bar.

```swift
HoldToConfirmButton("Hold to send", systemImage: "paperplane.fill") {
    try await transfer.send()
}
```

## Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [How it works](#how-it-works)
- [Guide](#guide)
  - [Labels](#labels) · [Async actions and outcomes](#async-actions-and-outcomes) · [Hold behaviors](#hold-behaviors) · [Directions and right-to-left](#directions-and-right-to-left)
  - [Themes and colors](#themes-and-colors) · [Size, shape and presets](#size-shape-and-presets) · [Knob icons](#knob-icons) · [Haptics](#haptics)
  - [Observing state](#observing-state) · [Accessibility](#accessibility) · [Placement](#placement) · [Previews and snapshot tests](#previews-and-snapshot-tests) · [UIKit](#uikit)
- [Hold to confirm: the circle](#hold-to-confirm-the-circle)
  - [Progress styles](#progress-styles) · [Completion styles](#completion-styles) · [States, sizes and labels](#states-sizes-and-labels)
  - [Placement and thumb reach](#placement-and-thumb-reach) · [iPhone Duo side bar](#iphone-duo-side-bar) · [UIKit](#uikit-1) · [Circle configuration reference](#circle-configuration-reference)
- [Configuration reference](#configuration-reference)
- [All states](#all-states)
- [Demo app](#demo-app)
- [Architecture and testing](#architecture-and-testing)
- [FAQ](#faq)
- [Contributing](#contributing) · [License](#license)

## Features

|  |  |
| --- | --- |
| 👆 **Slide or hold** | One control, two gestures. Take over a hold mid-way by dragging the knob from where it is. |
| ⭕️ **Or just a circle** | `HoldToConfirmButton`: ten progress styles, six completion styles, four sizes, five label positions. |
| 🖐️ **Built for reach** | Placements that keep the thumb in its natural zone for either hand, a reach model and a heat-map overlay. |
| 🎛️ **Every aspect is a setting** | 35+ options for interaction, timing, size, typography, knob, colors, motion and haptics, plus presets. |
| 🌗 **Themes** | Light and dark palettes, brand and colored surfaces, one-line tints, or fully custom palettes. |
| ⏳ **Async by design** | Processing while your action runs, success only when it returns, failure with a reason when it throws. No double sends. |
| ↔️ **Any direction** | Leading-to-trailing (mirrors in Arabic and Hebrew), down for vertical bars, up for doors and lifts. A 48 pt ring for side-bar items. |
| ♿️ **Accessible** | A button for VoiceOver, Switch Control and Voice Control, an optional confirmation alert, keyboard support, Dynamic Type and Reduce Motion. |
| 📳 **Haptics** | A tick when armed, rising ticks while holding, success and error notifications. Swap in your own engine. |
| 🧩 **SwiftUI and UIKit** | Native SwiftUI views and `UIControl`s with target-action and Auto Layout sizing. |
| 🧪 **Tested** | A pure, clock-free interaction engine with 65 unit tests on Linux and macOS, rendering tests, and UI tests that drive real touches. |
| 🌍 **Localized** | Built-in labels in English, Arabic, French, German and Spanish. |

## Screenshots

The [demo app](#demo-app) shows every scenario, a live playground and a gallery of states.

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/hold-light.png" width="200" alt="Hold tab"><br><sub><b>The circle</b></sub></td>
    <td align="center"><img src="docs/screenshots/hold-reach-light.png" width="200" alt="Thumb reach map"><br><sub><b>Thumb reach</b></sub></td>
    <td align="center"><img src="docs/screenshots/hold-duo-zone-light.png" width="200" alt="Hold ring in the vertical bar"><br><sub><b>Side-bar ring</b></sub></td>
    <td align="center"><img src="docs/screenshots/workout-dark.png" width="200" alt="End a workout"><br><sub><b>Countdown hold</b></sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/showcase-light.png" width="200" alt="Showcase"><br><sub><b>Showcase</b></sub></td>
    <td align="center"><img src="docs/screenshots/send-light.png" width="200" alt="Send money"><br><sub><b>Send money</b></sub></td>
    <td align="center"><img src="docs/screenshots/send-arabic-dark.png" width="200" alt="Send money in Arabic"><br><sub><b>Arabic, dark</b></sub></td>
    <td align="center"><img src="docs/screenshots/receipt-light.png" width="200" alt="Receipt"><br><sub><b>Receipt</b></sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/playground-light.png" width="200" alt="Playground"><br><sub><b>Playground</b></sub></td>
    <td align="center"><img src="docs/screenshots/states-dark.png" width="200" alt="States gallery"><br><sub><b>States gallery</b></sub></td>
    <td align="center"><img src="docs/screenshots/checkout.png" width="200" alt="Checkout on a brand surface"><br><sub><b>Brand surface</b></sub></td>
    <td align="center"><img src="docs/screenshots/delete-light.png" width="200" alt="Delete account"><br><sub><b>Destructive, fill hold</b></sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/tabzone-light.png" width="200" alt="Vertical bar"><br><sub><b>Vertical bar</b></sub></td>
    <td align="center"><img src="docs/screenshots/garage-light.png" width="200" alt="Garage door"><br><sub><b>Slide up</b></sub></td>
    <td align="center"><img src="docs/screenshots/sos-light.png" width="200" alt="Emergency SOS"><br><sub><b>Hold only</b></sub></td>
    <td align="center"><img src="docs/screenshots/unlock-dark.png" width="200" alt="Unlock"><br><sub><b>Slide only</b></sub></td>
  </tr>
</table>

<details>
<summary>More screenshots</summary>
<br>
<table>
  <tr>
    <td align="center"><img src="docs/screenshots/showcase-dark.png" width="200" alt="Showcase, dark"><br><sub>Showcase, dark</sub></td>
    <td align="center"><img src="docs/screenshots/scenarios-light.png" width="200" alt="Scenarios"><br><sub>Scenarios</sub></td>
    <td align="center"><img src="docs/screenshots/scenarios-dark.png" width="200" alt="Scenarios, dark"><br><sub>Scenarios, dark</sub></td>
    <td align="center"><img src="docs/screenshots/playground-dark.png" width="200" alt="Playground, dark"><br><sub>Playground, dark</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/states-light.png" width="200" alt="States, light"><br><sub>States, light</sub></td>
    <td align="center"><img src="docs/screenshots/tabzone-arabic.png" width="200" alt="Vertical bar in Arabic"><br><sub>Vertical bar, Arabic</sub></td>
    <td align="center"><img src="docs/screenshots/uikit-light.png" width="200" alt="UIKit"><br><sub>UIKit</sub></td>
    <td align="center"><img src="docs/screenshots/hold-dark.png" width="200" alt="Hold tab, dark"><br><sub>The circle, dark</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/hold-compose-light.png" width="200" alt="Circle composer"><br><sub>Circle composer</sub></td>
    <td align="center"><img src="docs/screenshots/hold-reach-left-dark.png" width="200" alt="Thumb reach, left hand"><br><sub>Reach, left hand, edge</sub></td>
    <td align="center"><img src="docs/screenshots/hold-duo-above-dark.png" width="200" alt="Ring above minimized tabs"><br><sub>Ring above tabs</sub></td>
    <td align="center"><img src="docs/screenshots/hold-duo-thumb-arabic.png" width="200" alt="Ring at thumb height in Arabic"><br><sub>Ring at thumb height, Arabic</sub></td>
  </tr>
</table>
</details>

## Requirements

| | Minimum |
| --- | --- |
| iOS / iPadOS / Mac Catalyst | 16.0 |
| macOS | 13.0 |
| Swift | 5.9 (Xcode 15) |
| Keyboard activation | iOS 17 / macOS 14 |

The interaction engine also builds and tests on Linux.

## Installation

### Xcode

**File › Add Package Dependencies…**, paste the URL and add **SlideToConfirm** to your target:

```
https://github.com/mohamedsalahnassar/SlideToConfirm
```

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/mohamedsalahnassar/SlideToConfirm", from: "1.0.0"),
],
targets: [
    .target(name: "MyApp", dependencies: ["SlideToConfirm"]),
]
```

## Quick start

```swift
import SlideToConfirm
import SwiftUI

struct ReviewTransferView: View {
    let transfer: Transfer

    var body: some View {
        ScrollView {
            TransferDetails(transfer: transfer)
        }
        .safeAreaInset(edge: .bottom) {
            SlideToConfirm("Slide or hold to send") {
                try await transfer.send()     // processing until this returns, then success
            }
            .padding()
        }
    }
}
```

That's all it takes. On iPhone the control fills the width; on iPad and Mac it stops growing at
440 pt and stays centered. If `send()` throws, the control shakes, shows the failure label and
returns to idle, ready to try again.

## How it works

```mermaid
flowchart LR
    T([Touch down]) -->|moved 6 pt along the knob| D[Drag]
    T -->|still for 180 ms| H[Hold<br/>knob glides, track fills]
    H -->|moved 12 pt on the knob| D
    H -->|lift early| B[Spring back]
    D -->|release before 90%| B
    D -->|release past 90%| C{{Commit · haptic}}
    H -->|held for 1.2 s| C
    K([Keyboard · VoiceOver]) --> C
    C --> P[Processing<br/>locked]
    P -->|action returns| S([Success])
    P -->|action throws| F[Failure<br/>shake · reason]
    F --> I([Idle])
    B --> I
```

1. **Touch down.** For 180 ms nothing moves. A 6 pt move along the track on the knob means drag; a
   still finger means hold.
2. **Hold glides the knob.** It travels at a steady pace and the track fills solid behind it. The
   label rides ahead of the knob, then hands over to a white label on the fill.
3. **Take over any time.** Move more than 12 pt on the knob while holding and you drag it from where
   it is. Lift early and it springs back.
4. **Same ending.** Commit at the end of the hold or past 90% of a drag: a haptic tick, processing,
   then success only after your action returns.

## Guide

### Labels

Name the action, not the gesture, and give every state its own words:

```swift
SlideToConfirm(labels: SlideToConfirmLabels(
    "Slide or hold to send",
    armed: "Release to send",          // past the commit threshold
    holding: "Keep holding…",
    processing: "Sending…",
    success: "Sent",
    failure: "Not sent · try again"
)) {
    try await transfer.send()
}
```

Labels you leave out use built-in text localized into English, Arabic, French, German and Spanish.
Keys are looked up in your app's `Localizable` table; pass `tableName:` and `bundle:` to use another.
For verbatim or styled text, use `SlideToConfirmLabels(idle: Text(…), armed: Text(…), …)`.

### Async actions and outcomes

The control is **locked** from the moment it commits until your action returns, so it can never fire
twice. It turns green only on success.

```swift
SlideToConfirm("Slide to pay") {
    guard wallet.balance >= amount else {
        throw SlideToConfirmFailure("Insufficient funds")   // shown on the control
    }
    try await wallet.pay(amount)                             // any other error shows the failure label
}
.slideToConfirmConfiguration {
    $0.successBehavior = .reset(after: 2)   // default is .remain: stays confirmed
    $0.failureDisplayDuration = 2.5         // touching it during failure retries straight away
}
```

| Your action… | The control… |
| --- | --- |
| returns | shows **success** and plays the success haptic. Stays there, or resets after a delay. |
| throws `SlideToConfirmFailure("…")` | shows your message, shakes and plays the error haptic, then returns to idle. |
| throws any other error | shows the **failure** label, shakes, then returns to idle. |
| throws `CancellationError` | returns to idle quietly. |

Want to know *how* it was confirmed? Take a `trigger`:

```swift
SlideToConfirm("Slide or hold to send") { trigger in
    analytics.log("send_confirmed", method: trigger.rawValue)  // drag, hold, holdThenDrag, keyboard, accessibility
    try await transfer.send()
}
```

To start over after a `.remain` success, give the control a new identity: `.id(attempt)`.

### Hold behaviors

All behaviors share the drag path. They differ only in what moves while the person holds.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/hold-behaviors-dark.png">
  <img src="docs/images/hold-behaviors-light.png" alt="Combined, fill and glide hold behaviors, early and late in a hold.">
</picture>

```swift
.slideToConfirmHoldBehavior(.fill)
```

| Behavior | While holding | Best for |
| --- | --- | --- |
| `.combined` *(default)* | The knob glides and a solid fill follows it. One progress value drives both, so they always agree, and the knob is already where the thumb expects it for a take-over. | Most screens. |
| `.fill` | The knob stays put and the track fills from the start edge; the label changes color exactly where the fill reaches. Drains back at 3× speed on early release. | Dense screens, destructive actions. |
| `.glide` | The knob slides by itself with the soft drag fill. Only the ring shows time left. | When hold should feel like an auto-slide. |
| `.none` | Nothing: slide only. A tap off the knob nudges it as a hint. | Unlock-style controls. |

**Hold only.** Turn off dragging for controls that must never fire from a stray swipe:

```swift
.slideToConfirmConfiguration(.holdOnly.with { $0.holdDuration = 3 })
```

### Directions and right-to-left

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/directions-dark.png">
  <img src="docs/images/directions-light.png" alt="Vertical tracks sliding down and up, and the horizontal track mirrored for Arabic.">
</picture>

```swift
SlideToConfirm("Slide down to send") { … }
    .slideToConfirmDirection(.down)      // .trailing (default), .down or .up
    .frame(height: 300)
```

- **`.trailing`** slides from the leading edge to the trailing edge and **mirrors automatically** in
  right-to-left layouts: the knob starts on the right and slides left. Text is never mirrored.
- **`.down`** and **`.up`** never mirror: down is down in every language. Give vertical tracks a height.

### Themes and colors

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/themes-dark.png">
  <img src="docs/images/themes-light.png" alt="Built-in themes: standard, positive, destructive, monochrome, tinted and brand.">
</picture>

Every theme has a light and a dark palette and follows the environment's color scheme.

```swift
.slideToConfirmTheme(.standard)                   // deep blue on white / bright blue on navy (default)
.slideToConfirmTheme(.accent)                     // follows your app's accent color
.slideToConfirmTheme(.positive)                   // green
.slideToConfirmTheme(.destructive)                // red
.slideToConfirmTheme(.monochrome)                 // ink on white / white on charcoal
.slideToConfirmTheme(.tinted(.orange))            // any color
.slideToConfirmTheme(.tinted(.indigo, dark: .mint))
.slideToConfirmTheme(.onColor(brandColor))        // translucent track + white knob for colored surfaces
.slideToConfirmTheme(.brand)                      // .onColor for a deep blue surface
```

For complete control, start from a palette and change what you need. Every color is exposed:

```swift
var light = SlideToConfirmPalette.light(accent: .indigo)
light.success = .mint
light.knobShadow = SlideToConfirmShadow(color: .indigo.opacity(0.4), radius: 6, y: 3)

var dark = SlideToConfirmPalette.dark(accent: .indigo)
dark.track = Color(white: 0.12)

.slideToConfirmTheme(SlideToConfirmTheme(light: light, dark: dark))
```

<details>
<summary>Palette colors</summary>

| Property | Used for |
| --- | --- |
| `track`, `trackBorder`, `trackShadow` | The bare track, its hairline and its shadow |
| `fill`, `armedFill` | The soft fill that follows a drag, before and after the commit threshold |
| `solidFill`, `onSolidFill` | The solid fill while holding and processing, and the label and knob drawn on it |
| `knob`, `knobIcon`, `knobShadow` | The knob, its icon and countdown ring, and its shadow |
| `label`, `dimmedLabel` | The label, and the dim part of the idle shimmer |
| `failureLabel` | The failure label |
| `ringTrack`, `invertedRingTrack` | The unfilled countdown ring on the regular and inverted knob |
| `success`, `onSuccess` | The track after success, and the label and knob on it |

</details>

### Size, shape and presets

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/customization-dark.png">
  <img src="docs/images/customization-light.png" alt="Compact, large, rounded, custom-knob and failure-with-reason variants.">
</picture>

```swift
.slideToConfirmConfiguration {
    $0.thickness = 64          // track height (width for vertical tracks)
    $0.knobInset = 5           // gap around the knob
    $0.maxLength = 480         // stops growing here; nil fills any width
    $0.cornerRadius = 14       // nil = capsule
    $0.labelSize = 16
    $0.labelWeight = .bold
    $0.labelDesign = .rounded
}
```

Presets give you a head start; `with { }` adjusts any of them:

| Preset | |
| --- | --- |
| `.default` | 60 pt combined slide-or-hold, capped at 440 pt |
| `.compact` | 48 pt track, 14 pt label |
| `.large` | 72 pt track, 17 pt label |
| `.verticalBar` | 56 pt pull-down track for a vertical tab-bar zone |
| `.slideOnly` | Holding does nothing |
| `.holdOnly` | The knob can't be dragged; the track fills while held |

```swift
.slideToConfirmConfiguration(.compact.with { $0.theme = .positive })
```

### Knob icons

Built-in icons are drawn to match the design and turn with the direction. Use any SF Symbol instead:

```swift
.slideToConfirmConfiguration {
    $0.icons = SlideToConfirmIcons(
        idle: .systemImage("lock.fill"),
        processing: .spinner,
        success: .systemImage("lock.open.fill"),
        failure: .exclamationmark
    )
    // .chevron, .arrow, .checkmark, .exclamationmark, .spinner,
    // .systemImage("…", followsDirection: true), .none
}
```

Or draw your own view. The knob keeps its shape, color, shadow and countdown ring:

```swift
.slideToConfirmKnob { knob in
    Image(systemName: knob.state.phase == .success ? "lock.open.fill" : "lock.fill")
        .font(.system(size: knob.diameter * 0.36, weight: .bold))
        .foregroundStyle(knob.iconColor)          // follows inversion and success
}
```

### Haptics

| Moment | Event | Default on iPhone |
| --- | --- | --- |
| A still finger becomes a hold | `.holdBegan` | Light impact |
| Hold passes 25, 50, 75% | `.holdProgress(_:)` | Soft impact, stronger each time |
| A drag crosses the threshold | `.armed` | Medium impact |
| The control commits | `.confirmed` | Rigid impact |
| The action succeeds / fails | `.success` / `.failure` | Success / error notification |

```swift
.slideToConfirmHaptics(.disabled)
.slideToConfirmHaptics(.custom { event in
    MyHapticEngine.play(event)
})
.slideToConfirmConfiguration { $0.holdHapticMarks = 5 }   // ticks at 1/6, 2/6, … of the hold
```

On a Mac with a Force Touch trackpad the defaults play trackpad feedback.

### Observing state

React to the control while it's in use, for example to drive an illustration or a readout.
The handler runs on the main actor for every change, including continuous progress while dragging or holding, and its last call always matches what the control is doing:

```swift
@State private var openness = 0.0

SlideToConfirm("Slide up to open") { try await garage.open() }
    .slideToConfirmDirection(.up)
    .onSlideToConfirmStateChange { state in
        openness = state.progress            // 0...1
        // state.phase: .idle, .processing, .success, .failure
        // state.interaction: .none, .pending, .dragging, .holding
        // state.isArmed: releasing now would confirm
    }
```

### Accessibility

VoiceOver, Switch Control and Voice Control see **one button** named after the idle label, with the
hint "Double-tap to confirm." Activating it snaps the knob to the end and runs the action.

```swift
SlideToConfirm("Slide or hold to send") { try await transfer.send() }
    .accessibilityLabel("Send AED 2,500 to Sara Ahmed")       // name the action, not the gesture
    .slideToConfirmAccessibilityAlert(                         // a second step for consequential actions
        "Send AED 2,500 to Sara Ahmed?",
        message: "The money arrives today, within minutes."
    )
```

- **Keyboard.** Return or Space confirms when the control has focus (iOS 17, macOS 14).
- **Dynamic Type.** The label scales up to `maximumDynamicTypeSize`; at accessibility sizes the track
  grows to fit and never shrinks below `thickness`.
- **Reduce Motion.** No shimmer, no overshoot, no shake. The glide and fill still run because they
  carry meaning.
- **Disabled.** `.disabled(true)` dims the control and blocks every input, and is announced.
- **Status.** Processing, success and failure are exposed as the accessibility value.

### Placement

**At the bottom of a task screen**, where the thumb rests:

```swift
.safeAreaInset(edge: .bottom) {
    SlideToConfirm("Slide or hold to send") { try await send() }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
}
```

**On iPad and Mac** the control is capped at `maxLength` (440 pt) and centered. Align it with
`.frame(maxWidth: .infinity, alignment: .trailing)` in a form sheet.

**In a vertical bar.** On layouts with a trailing vertical bar, such as iPhone Duo's outer display,
let the control take the tab bar's zone as a pull-down track on the Review screen. The bar stays on
the trailing hardware edge in every language, so the control doesn't mirror:

```swift
SlideToConfirm("Slide or hold to send") { try await send() }
    .slideToConfirmConfiguration(.verticalBar)   // .down, 56 pt wide
    .frame(height: 300)
```

<details>
<summary>iPhone Duo toolbar placement (iOS 27.1)</summary>

Put the control in a bottom toolbar item that prefers the vertical axis, and free the zone by hiding
the tab bar on the task screen. These APIs are new in iOS 27.1; confirm exact signatures in Xcode.

```swift
ReviewTransfer()
    .toolbarVisibility(.hidden, for: .tabBar)          // or .toolbarVerticalCompressionBehavior(.prefersToolbarItems)
    .toolbar {
        ToolbarItem(placement: .bottomBar) { TabZoneConfirm(onConfirm: send) }
            .axisBehavior(.verticalPreferred)
    }

struct TabZoneConfirm: View {
    let onConfirm: () async throws -> Void
    @Environment(\.toolbarVerticalEdge) private var edge   // nil = horizontal bars

    var body: some View {
        SlideToConfirm("Slide or hold to send", action: onConfirm)
            .slideToConfirmConfiguration(edge != nil ? .verticalBar : .default)
            .frame(height: edge != nil ? 300 : nil)
    }
}
```

The demo app's **Vertical bar** scenario simulates this layout on any iPhone.
</details>

If the bar won't give one item 300 pt, a 48 pt [hold ring](#iphone-duo-side-bar) fits an ordinary
item and keeps the idea.

> **Inside a `ScrollView`?** The control claims touches that start on it, like a slider does, so a
> scroll that starts on the control won't scroll. Pin it outside the scroll view where you can.

### Previews and snapshot tests

Freeze the control in any state. A frozen control ignores touches and draws deterministically,
which makes it ideal for `#Preview`, design-system galleries and snapshot tests:

```swift
#Preview("States") {
    VStack(spacing: 16) {
        SlideToConfirm("Slide or hold to send") {}.slideToConfirmPreviewState(.idle)
        SlideToConfirm("Slide or hold to send") {}.slideToConfirmPreviewState(.holding(progress: 0.6))
        SlideToConfirm("Slide or hold to send") {}.slideToConfirmPreviewState(.armed())
        SlideToConfirm("Slide or hold to send") {}.slideToConfirmPreviewState(.failure(message: "No connection"))
    }
    .padding()
}
```

`SlideToConfirmPreviewState`: `.idle`, `.dragging(progress:)`, `.armed(progress:)`,
`.holding(progress:)`, `.processing`, `.success`, `.failure(message:)`, `.disabled`.

### UIKit

`SlideToConfirmControl` wraps the SwiftUI control in a `UIControl`:

```swift
import SlideToConfirm
import UIKit

let control = SlideToConfirmControl(title: "Slide or hold to approve")
control.configuration = .default.with { $0.theme = .positive }
control.action = { trigger in
    try await expenses.approve(report)
}
control.addAction(UIAction { _ in
    Analytics.log("approve_committed")
}, for: .primaryActionTriggered)           // sent when it commits, before the action runs
control.confirmationStateDidChange = { state in
    print(state.phase, state.progress)     // also sent as .valueChanged
}

view.addSubview(control)
control.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    control.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
    control.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    control.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
])                                          // height comes from its intrinsic size

control.reset()                             // back to idle, for example after success
```

It also exposes `labels`, `haptics`, `previewState`, `confirmationState`, `lastTrigger` and honors
`isEnabled`.

## Hold to confirm: the circle

`HoldToConfirmButton` is the compact sibling of the pill: a circle you press and hold. It runs on
the same engine, so it shares the haptics, labels, themes, async outcomes and accessibility, and it
fits where a 300 pt track can't: a floating corner, a card, a toolbar or a 56 pt side bar.

<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/hold-demo-dark.gif">
  <img src="docs/images/hold-demo-light.gif" width="520" alt="A tap shows the “Press and hold” hint; a short hold drains back; a full hold fills the ring, shows processing, then morphs into a capsule that reads Sent.">
</picture>
</p>

```swift
HoldToConfirmButton("Hold to send", systemImage: "paperplane.fill") {
    try await transfer.send()
}
```

| Gesture | What happens |
| --- | --- |
| **Press and hold** | The circle presses in under the finger, and after 100 ms the progress style starts. At the end it commits with the confirm haptic, shows processing while your action runs, then success. |
| **Let go early** | Progress drains back three times faster than it filled. Press again before it empties and it picks up from there. Prefer a clean restart? `releaseBehavior = .reset`. |
| **Slide off** | Moving the finger more than 24 pt outside the circle cancels, like any button. |
| **Tap** | The circle pulses and the label briefly reads **Press and hold** (`SlideToConfirmLabels.tapHint`), so people learn the gesture. |
| **VoiceOver, Switch Control, keyboard** | It's a button named after its label. Activation fills the ring, then runs the action; add `.slideToConfirmAccessibilityAlert(_:)` for a second step. |

<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/hold-hero-dark.png">
  <img src="docs/images/hold-hero-light.png" width="720" alt="The circle idle, holding at 62%, processing and succeeded.">
</picture>
</p>

### Progress styles

Ten ways to show that a hold is under way and how long is left. They all show the same progress;
they differ in what moves.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/hold-progress-dark.png">
  <img src="docs/images/hold-progress-light.png" alt="Ring, segments, fill, liquid, radial, pie, pulse, glow, orbit and countdown, each holding at 60%.">
</picture>

| Style | What moves | Reach for it when |
| --- | --- | --- |
| `.ring` | A ring fills clockwise around the circle. | You want the clearest countdown. The default. |
| `.segments` | Ticks light up one by one, each with a haptic tick. | The hold is long, or people may not be looking. |
| `.fill` | The circle fills from the bottom; the icon turns white exactly where the fill reaches. | The action is destructive or the screen is calm. |
| `.liquid` | Like `.fill`, with a moving wave on the surface. | The moment deserves some play. |
| `.radial` | A disc grows from the center outward. | The circle is small, such as in a toolbar. |
| `.pie` | A sector sweeps like a clock hand. | The action is about time. |
| `.pulse` | Ripples radiate, faster toward the end, over a thin ring. | The action is urgent, such as SOS. |
| `.glow` | A halo grows brighter and wider. | You want the least motion; time left is implied. |
| `.orbit` | A comet orbits the circle, its tail growing. | Media and expressive brands. |
| `.countdown` | The seconds left count down inside a ring. | Long, deliberate holds of 3 s or more. |

Every style also gets the shared feedback: the circle presses in to 94% under the finger, rising
haptic ticks mark the way (one per segment with `.segments`), and a failure shakes the circle red.

### Completion styles

Success shows only after your action returns. Pick how it lands:

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/hold-completion-dark.png">
  <img src="docs/images/hold-completion-light.png" alt="Check mark, ripple, burst, bounce, morph into a Sent capsule, and flip, each caught mid-animation.">
</picture>

| Style | What happens |
| --- | --- |
| `.checkmark` | The circle turns green and a check mark draws itself in. The default. |
| `.ripple` | A shock wave rings out from the circle. |
| `.burst` | Particles burst outward and fade. |
| `.bounce` | The circle pops with an overshoot. |
| `.morph` | The circle stretches into a capsule that spells out the success label. |
| `.flip` | The circle flips over, from the processing face to the success face. |

With Reduce Motion on, every style jumps straight to its final frame, without movement.

```swift
HoldToConfirmButton("Hold to send", systemImage: "paperplane.fill") { try await send() }
    .holdToConfirmProgressStyle(.liquid)
    .holdToConfirmCompletionStyle(.burst)
```

### States, sizes and labels

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/hold-states-dark.png">
  <img src="docs/images/hold-states-light.png" alt="The compact circle idle, holding, processing, succeeded, failed and disabled.">
</picture>

| Preset | Circle | With ring | Use it for |
| --- | --- | --- | --- |
| `.default` | 88 pt | 110 pt | A floating action or a card. Label below. |
| `.compact` | 56 pt | 72 pt | Dense rows and toolbars. |
| `.large` | 128 pt | 158 pt | A screen whose one job is this confirmation. |
| `.verticalBar` | 36 pt | 48 pt | An ordinary item in a 56 pt vertical bar. Label hidden. |
| `.destructive` | 88 pt | 110 pt | Red, filling from the bottom, two seconds long. |

The label sits `.below`, `.above`, `.leading` or `.trailing` the circle, or is `.hidden` (it remains
the accessibility label). It follows the phase: **Keep holding…** while holding, **Press and hold**
after a tap, then processing, success or the failure reason.

```swift
HoldToConfirmButton(labels: SlideToConfirmLabels(
    "Hold to end",
    holding: "Keep holding…",
    processing: "Saving…",
    success: "Saved",
    tapHint: "Hold to end · tap Pause"
), systemImage: "stop.fill") {
    try await workout.end()
}
.holdToConfirmConfiguration(.large.with {
    $0.holdDuration = 3
    $0.progressStyle = .countdown
    $0.completionStyle = .morph
    $0.theme = .tinted(.red)
})
```

### Placement and thumb reach

A hold needs a resting thumb: people can't keep a finger down for a second while stretching for the
top of the screen. `ThumbReach` models where the thumb reaches on a phone held in one hand, from the
base of the thumb near the bottom corner, and every placement keeps the circle in the **natural**
zone of the hand it names.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/hold-placements-dark.png">
  <img src="docs/images/hold-placements-light.png" alt="Phone screens for the right and left hand with a green, yellow and red reach heat map, and the four placements marked on each.">
</picture>

| Placement | Where | Reach for it when |
| --- | --- | --- |
| `.bottomCenter` | Centered, above the bottom edge. | Either hand may hold the phone, and people look here first for the primary action. The safest default. |
| `.bottomCorner(hand)` | The bottom corner on the side of the hand. | A floating action button. Keep the margin; the very corner makes the thumb curl. |
| `.thumbArc(hand)` | About two thirds down, in from the edge. | The hold is long. This is where the thumb rests, so it's the most comfortable spot to keep it down. |
| `.edge(hand)` | Against the edge, a little below the middle. | The bottom belongs to a tab bar, or you want a side-bar feel. |

```swift
CheckoutScreen()
    .holdToConfirmOverlay(.thumbArc(.right)) {
        HoldToConfirmButton("Hold to pay", systemImage: "creditcard.fill") { try await pay() }
    }
```

- **Placements name a hand, not leading or trailing.** Reach is physical: in Arabic the right thumb
  still rests on the right, so placements don't mirror. Offer a handedness setting and use
  `placement.mirrored` for left-handed people.
- **Inline works too.** In a card or list row use `.compact` with a `.trailing` label; in a toolbar,
  `.compact` or `.verticalBar` with the label hidden.
- **Avoid** the top half of the screen and the top corners (hard to reach one-handed), and anywhere
  a scroll starts: the circle claims touches that start on it.
- **Check your own layouts** with the heat map, then take it out:

```swift
ReviewScreen()
    .overlay { ThumbReachOverlay(hand: .right).ignoresSafeArea() }

ThumbReach.zone(at: buttonCenter, in: screenSize, hand: .left)   // .natural, .stretch or .hard
```

On iPad and Mac reach matters less: place the circle next to what it confirms.

### iPhone Duo side bar

Closed, iPhone Duo puts a vertical bar on the trailing hardware edge, with the tab bar at its
bottom under the thumb. The pill can take the tab zone as a 300 pt pull-down track (see
[Placement](#placement)), but Apple documents a fixed width and flexible item height for vertical
bars, not how tall one custom item may grow. The circle needs no extra height: the `.verticalBar`
preset is a 48 pt ring that fits an ordinary 56 pt item.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/hold-duo-dark.png">
  <img src="docs/images/hold-duo-light.png" alt="Three outer-display mock-ups with the hold ring in the trailing bar: in the tab zone, above a minimized tab, and at thumb height above the full tabs.">
</picture>

| Position | How | Trade-off |
| --- | --- | --- |
| **In the tab zone** | Hide the tabs on the task screen; the ring takes their place at the bottom of the bar. | Exactly under the thumb and unmistakably the primary action. Tabs return after. |
| **Above minimized tabs** | Minimize the tabs to the current one; the ring sits right above it. | Navigation stays one tap away; the ring is 56 pt higher, still natural reach. |
| **At thumb height** | Leave the tabs alone; the ring sits just above them, where the thumb wraps the edge. | No change to navigation. Keep it in the lower half of the bar: the upper half is out of reach. |

The bar, and the ring in it, stay on the trailing hardware edge in every language, and the ring
fills clockwise everywhere, like a clock. Open the phone and turn the inner display to portrait, and
the bars go horizontal: the same item becomes a bottom toolbar item, where `.compact` with a
trailing label reads better.

<details>
<summary>Toolbar placement sketch (iOS 27.1)</summary>

These APIs are new in iOS 27.1; confirm exact signatures in Xcode.

```swift
ReviewTransfer()
    .toolbarVisibility(.hidden, for: .tabBar)       // "In the tab zone"; omit for "At thumb height"
    .toolbar {
        ToolbarItem(placement: .bottomBar) { SideBarConfirm(onConfirm: send) }
            .axisBehavior(.verticalPreferred)
    }

struct SideBarConfirm: View {
    let onConfirm: () async throws -> Void
    @Environment(\.toolbarVerticalEdge) private var edge   // nil = horizontal bars

    var body: some View {
        HoldToConfirmButton("Hold to send", systemImage: "paperplane.fill", action: onConfirm)
            .holdToConfirmConfiguration(edge != nil ? .verticalBar : .compact.with { $0.labelPosition = .trailing })
    }
}
```
</details>

The demo app's **Vertical bar · iPhone Duo** scenario simulates all three positions on any iPhone,
in English and Arabic.

### UIKit

```swift
let control = HoldToConfirmControl(title: "Hold to flag", systemImage: "flag.fill", configuration: .compact)
control.action = { trigger in
    try await reports.flag(item)
}
control.addAction(UIAction { _ in Analytics.log("flag_committed") }, for: .primaryActionTriggered)
view.addSubview(control)   // sizes itself from its intrinsic content size
```

Like `SlideToConfirmControl`, it exposes `labels`, `configuration`, `haptics`, `previewState`,
`confirmationState`, `confirmationStateDidChange`, `lastTrigger`, `reset()` and honors `isEnabled`.

### Circle configuration reference

Set any of these with `.holdToConfirmConfiguration { $0.… = … }`.

| Property | Default | Description |
| --- | --- | --- |
| `holdDuration` | `1.2` s | How long the hold takes. |
| `holdDelay` | `0.1` s | How long a finger rests before the hold starts. |
| `releaseBehavior` | `.drain` | `.drain` back on early release, or `.reset` to zero. |
| `drainSpeed` | `3` | How many times faster it drains than it filled. |
| `outsideTolerance` | `24` pt | How far outside the circle a finger may stray before the hold cancels. |
| `hintsOnTap` | `true` | A tap pulses the circle and shows the tap hint. |
| `activationDelay` | `0.36` s | Pause between filling and the action, for keyboard and assistive activation. |
| `successBehavior` | `.remain` | `.remain` or `.reset(after:)`. |
| `failureDisplayDuration` | `2` s | How long failure shows before idle. |
| `shakesOnFailure` | `true` | Shake when the action fails (skipped with Reduce Motion). |
| `diameter` | `88` pt | The circle's diameter. |
| `ringWidth` · `ringGap` | `6` · `5` pt | The ring's line width and its gap from the circle. |
| `segmentCount` | `12` | Ticks for `.segments`. |
| `pressedScale` | `0.94` | How much the circle shrinks under the finger. |
| `iconScale` | `0.34` | The icon's size relative to the diameter. |
| `labelPosition` | `.below` | `.below`, `.above`, `.leading`, `.trailing` or `.hidden`. |
| `labelFont` · `labelSize` · `labelWeight` | `nil` · `15` · `.semibold` | The label's font. |
| `labelSpacing` | `12` pt | Gap between the circle and the label. |
| `maximumDynamicTypeSize` | `.accessibility3` | Largest text size the label follows. |
| `progressStyle` | `.ring` | One of the ten progress styles. |
| `completionStyle` | `.checkmark` | One of the six completion styles. |
| `icons` | `hand.tap.fill` | Icons for idle, processing, success and failure. `systemImage:` sets the idle one. |
| `theme` | `.standard` | The same themes as the pill. |
| `showsShadow` | `true` | Shadow under the circle. |
| `disabledOpacity` · `animations` · `holdHapticMarks` | `0.42` · `.default` · `3` | As for the pill. |

| Modifier | Purpose |
| --- | --- |
| `.holdToConfirmConfiguration(_:)` · `.holdToConfirmConfiguration { }` | Set or adjust the configuration. |
| `.holdToConfirmProgressStyle(_:)` · `.holdToConfirmCompletionStyle(_:)` · `.holdToConfirmTheme(_:)` | Shortcuts. |
| `.holdToConfirmOverlay(_:margin:content:)` | Float a circle at a placement. |
| `.onHoldToConfirmStateChange { state in … }` | Observe phase, interaction and progress. |
| `.holdToConfirmPreviewState(_:)` | Freeze `.idle`, `.holding(progress:)`, `.processing`, `.success`, `.failure(message:)` or `.disabled`. |
| `.slideToConfirmHaptics(_:)` · `.slideToConfirmAccessibilityAlert(…)` | Shared with the pill. |

## Configuration reference

Set any of these with `.slideToConfirmConfiguration { $0.… = … }`. Configurations cascade through the
environment like other SwiftUI styles, so you can set a look once for a whole screen.

#### Interaction

| Property | Default | Description |
| --- | --- | --- |
| `direction` | `.trailing` | `.trailing`, `.down` or `.up`. |
| `holdBehavior` | `.combined` | `.combined`, `.fill`, `.glide` or `.none`. |
| `allowsDragging` | `true` | `false` makes a hold-only control. |
| `commitThreshold` | `0.9` | How far a drag must go before releasing confirms (0–1). |
| `holdDuration` | `1.2` s | Time from the start of a hold to the end of the track. |
| `holdDelay` | `0.18` s | How long a finger must stay still before it counts as a hold. |
| `dragActivationDistance` | `6` pt | Movement along the track, on the knob, that starts a drag. |
| `holdCancellationDistance` | `12` pt | Movement that takes over a hold (on the knob) or cancels it (elsewhere). |
| `fillDrainSpeed` | `3` | How many times faster the `.fill` drains than it filled. |
| `nudgesOnTap` | `true` | A quick tap hops the knob to hint that it slides. |
| `activationDelay` | `0.36` s | Pause between the knob snapping to the end and the action, for keyboard and assistive activation. |

#### Outcome

| Property | Default | Description |
| --- | --- | --- |
| `successBehavior` | `.remain` | `.remain` or `.reset(after:)`. |
| `failureDisplayDuration` | `2` s | How long the failure label shows before idle. |
| `shakesOnFailure` | `true` | Shake when the action fails (skipped with Reduce Motion). |

#### Size

| Property | Default | Description |
| --- | --- | --- |
| `thickness` | `60` pt | Track height, or width for vertical tracks. |
| `knobInset` | `4` pt | Gap between the knob and the track edge. |
| `maxLength` | `440` pt | Longest the track grows; `nil` fills any width. |
| `idealLength` | `320` pt | Length when the container doesn't propose one. |
| `cornerRadius` | `nil` | `nil` for a capsule, or a corner radius. |
| `growsWithDynamicType` | `true` | Thicken the track to fit the label at accessibility sizes. |
| `maximumDynamicTypeSize` | `.accessibility3` | Largest text size the label follows. |

#### Label

| Property | Default | Description |
| --- | --- | --- |
| `labelFont` | `nil` | A custom `Font`; `nil` builds a system font from the values below. |
| `labelSize` | `15` pt | Size at the default text size. |
| `labelWeight` | `.semibold` | Font weight. |
| `labelDesign` | `.default` | `.default`, `.rounded`, `.serif` or `.monospaced`. |
| `labelTracking` | `-0.15` pt | Letter spacing. |
| `labelEdgePadding` | `20` pt | Gap between the label and the end of the track. |
| `labelKnobSpacing` | `6` pt | Gap between the label and the knob. |
| `shimmer` | `true` | Idle shimmer toward the end (off with Reduce Motion). |
| `shimmerDuration` | `2.4` s | One shimmer cycle. |

#### Knob

| Property | Default | Description |
| --- | --- | --- |
| `icons` | `.default` | Icons for idle, processing, success and failure. |
| `showsHoldRing` | `true` | Countdown ring on the knob while holding. |
| `ringLineWidth` | `2.5` pt | Ring line width. |
| `armedKnobScale` | `1.05` | Knob scale once a drag passes the threshold. |

#### Appearance and motion

| Property | Default | Description |
| --- | --- | --- |
| `theme` | `.standard` | Light and dark palettes. |
| `disabledOpacity` | `0.42` | Opacity when disabled. |
| `animations` | `.default` | `springBack`, `snap`, `nudge`, `transition` and `reducedMotion` animations. |
| `holdHapticMarks` | `3` | Haptic ticks during a hold, evenly spaced. |

#### Modifiers

| Modifier | Purpose |
| --- | --- |
| `.slideToConfirmConfiguration(_:)` | Set a whole configuration. |
| `.slideToConfirmConfiguration { }` | Adjust the inherited configuration. |
| `.slideToConfirmTheme(_:)` · `.slideToConfirmDirection(_:)` · `.slideToConfirmHoldBehavior(_:)` | Shortcuts for the most common settings. |
| `.slideToConfirmHaptics(_:)` | `.automatic`, `.disabled` or `.custom { }`. |
| `.slideToConfirmKnob { knob in … }` | Custom knob content. |
| `.slideToConfirmAccessibilityAlert(_:message:confirmLabel:cancelLabel:)` | Confirm assistive-technology activation in an alert. |
| `.onSlideToConfirmStateChange { state in … }` | Observe phase, interaction and progress. |
| `.slideToConfirmPreviewState(_:)` | Freeze a state for previews and snapshots. |

Full API documentation is in the DocC catalog: in Xcode choose **Product › Build Documentation**.

## All states

Every state in light, dark and on a brand surface, rendered from the real control by
[`ReadmeImageTests`](Tests/SlideToConfirmTests/ReadmeImageTests.swift):

<img src="docs/images/states.png" alt="Idle, holding early, holding late, dragging, armed, processing, success, failure and disabled states in light, dark and brand.">

## Demo app

Open **`Example/SlideToConfirmDemo.xcodeproj`** and run it on an iPhone or iPad simulator (iOS 17+).
It uses the package from this repository, so your changes show up immediately.

| Tab | What's inside |
| --- | --- |
| **Showcase** | The hero control with a live readout of what it's doing, how it works, and Combined, Fill and Glide side by side. |
| **Hold** | The circle: a live hero with a readout, every progress and completion style to try, a composer that writes the code, a thumb-reach map with every placement for either hand, and the iPhone Duo side-bar ring. |
| **Scenarios** | Nine complete screens: send money (with failure and retry, Arabic and right-to-left), unlock, checkout on a brand surface, delete account, emergency SOS, a garage door driven by `onSlideToConfirmStateChange`, ending a workout with a countdown hold, a vertical bar with a track or a hold ring, and a UIKit screen with both controls. |
| **Playground** | Every setting as a live control, on light, dark and brand surfaces, with the Swift code for your configuration ready to copy. |
| **States** | Every state of the pill and the circle frozen with preview states, vertical tracks and right-to-left. |

Launch arguments open a screen directly, which the UI tests and screenshot workflow use:

```sh
xcrun simctl launch booted io.github.mohamedsalahnassar.SlideToConfirmDemo \
  -screen send -appearance dark -language ar
# -screen: showcase, hold, scenarios, playground, states, send, unlock, checkout, delete, sos, garage,
#          workout, tabzone, uikit, hold-compose, hold-reach, hold-duo, record, record-hold
# tabzone: -step review -control ring -ring zone|above|thumb · hold-reach: -hand left -placement edge
```

## Architecture and testing

```
Sources/SlideToConfirm
├── Engine/          ConfirmEngine: a pure value-type state machine. No UI, no clock.
├── Model/           Public state, phases, triggers, hold behaviors, preview states.
├── Configuration/   Configuration, themes and palettes, labels, icons, haptics.
├── Views/           The SwiftUI control, the track renderer, knob icons and effects.
├── Hold/            HoldToConfirmButton, its renderer and configuration, placements, ThumbReach.
├── Support/         Environment keys and modifiers.
└── UIKit/           SlideToConfirmControl and HoldToConfirmControl.
```

- **The engine never reads the clock.** Touches arrive with timestamps; the view asks for a snapshot
  per frame while a hold or drain is running, and wakes the engine at its next deadline. Every
  timing path is tested to the millisecond, on Linux and macOS.
- **One renderer, every direction.** The track is laid out horizontally from the leading edge,
  mirrored by geometry (never by flipping text) for right-to-left, and rotated for vertical tracks.
- **One engine, two shapes.** The circle drives the same engine as a hold-only track with no knob,
  reporting a finger outside the circle as a cancelling move. Completion effects are pure functions
  of one animatable value, so every frame can be rendered deterministically.
- **No double sends.** The engine locks from commit until the action reports back, ignoring every
  touch, key and assistive activation in between.

| Suite | Runs on | Covers |
| --- | --- | --- |
| `ConfirmEngineTests` | Linux, macOS, iOS | Drag, hold, take-over, nudge, fill drain, glide, outcomes, activation, disabling, settings |
| `TrackLayoutTests` | Linux, macOS, iOS | Knob and fill geometry, label regions and the combined-hold hand-over |
| `HoldEngineTests` | Linux, macOS, iOS | The circle's hold, drain and resume, reset, slide-off, tap hint, segment haptics, activation, retry |
| `ThumbReachTests` | Linux, macOS, iOS | The reach zones for either hand |
| `RenderingTests` · `HoldRenderingTests` | macOS, iOS | Every state × behavior × direction, and every progress, completion, label position and preset, renders; sizing; themes; right-to-left; placements stay in natural reach |
| `SlideToConfirmDemoUITests` · `HoldToConfirmUITests` | iOS | Real touches: hold, drag, early release, right-to-left drag, tap hint, slide-off, the side-bar ring, and every demo screen |

```sh
swift test
xcodebuild test -scheme SlideToConfirm -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild test -project Example/SlideToConfirmDemo.xcodeproj -scheme SlideToConfirmDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## FAQ

<details>
<summary><b>How do I let people confirm again after success?</b></summary>

Use `successBehavior = .reset(after:)`, or keep the default `.remain` and give the control a new
identity when you want a fresh one: `.id(attempt)`. With UIKit, call `reset()`.
</details>

<details>
<summary><b>Can I navigate away when it succeeds?</b></summary>

Yes. Watch for success and move on after a short beat so people see the confirmation:

```swift
.onSlideToConfirmStateChange { state in
    guard state.phase == .success else { return }
    Task {
        try? await Task.sleep(for: .milliseconds(700))
        path.append(.receipt)
    }
}
```
</details>

<details>
<summary><b>What happens if the view disappears while the action runs?</b></summary>

The action keeps running to completion; the control never cancels your work. Cancel it yourself if
that's what you want.
</details>

<details>
<summary><b>Does it work with my own localization?</b></summary>

Yes. Labels are `LocalizedStringKey`s looked up in your app's strings (or a table and bundle you
pass). Built-in fallback labels ship in English, Arabic, French, German and Spanish; contributions
for more languages are welcome.
</details>

<details>
<summary><b>Why doesn't the control fill the whole width on iPad?</b></summary>

It is capped at `maxLength` (440 pt) so the thumb never travels across a whole screen. Set
`maxLength = nil` to fill any width.
</details>

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for how the code is
organized, how to run the tests and how the README images are generated.

## License

SlideToConfirm is available under the MIT license. See [LICENSE](LICENSE).
