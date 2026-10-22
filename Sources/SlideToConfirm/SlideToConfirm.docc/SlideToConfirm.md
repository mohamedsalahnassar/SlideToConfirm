# ``SlideToConfirm``

A confirm control you can slide to the end, or simply press and hold.

## Overview

Consequential actions, such as sending money, deleting data or unlocking a door, deserve a gesture
that can't happen by accident but stays effortless on purpose. `SlideToConfirm` offers two:

- **Slide** the knob past 90% of the track and let go.
- **Press and hold** anywhere on the pill. After 180 ms the knob glides to the end by itself
  and the track fills behind it. Let go early and it springs back.

Both paths commit at the same point, play the same haptics and land in the same states:
processing while your action runs, then success, or failure with a shake and a reason.

```swift
import SlideToConfirm

SlideToConfirm("Slide or hold to send") {
    try await transfer.send()
}
```

Every aspect is configurable: hold behavior, direction, timing, size, typography, knob, colors,
motion and haptics. It is accessible out of the box, mirrors for right-to-left languages, scales
with Dynamic Type and has a UIKit wrapper.

Where a track doesn't fit, ``HoldToConfirmButton`` is the same control as a circle you press and
hold. See <doc:HoldToConfirm>.

## Topics

### Essentials

- <doc:GettingStarted>
- ``SlideToConfirm/SlideToConfirm``
- ``SlideToConfirmLabels``

### Hold to confirm

- <doc:HoldToConfirm>
- ``HoldToConfirmButton``
- ``HoldToConfirmConfiguration``

### Customizing

- <doc:Customization>
- ``SlideToConfirmConfiguration``
- ``SlideToConfirmHoldBehavior``
- ``SlideToConfirmDirection``
- ``SlideToConfirmSuccessBehavior``
- ``SlideToConfirmAnimations``

### Appearance

- ``SlideToConfirmTheme``
- ``SlideToConfirmPalette``
- ``SlideToConfirmShadow``
- ``SlideToConfirmIcons``
- ``SlideToConfirmIcon``
- ``SlideToConfirmKnobContext``

### Feedback and state

- ``SlideToConfirmHaptics``
- ``SlideToConfirmHapticEvent``
- ``SlideToConfirmState``
- ``SlideToConfirmPhase``
- ``SlideToConfirmInteraction``
- ``SlideToConfirmTrigger``
- ``SlideToConfirmFailure``

### Placement and accessibility

- <doc:VerticalBarPlacement>
- <doc:Accessibility>

### Previews and testing

- ``SlideToConfirmPreviewState``

### UIKit

- ``SlideToConfirmControl``
- ``HoldToConfirmControl``
