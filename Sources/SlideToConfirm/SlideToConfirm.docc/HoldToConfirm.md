# Hold to confirm

A circle you press and hold: the compact sibling of the slide-to-confirm pill.

## Overview

``HoldToConfirmButton`` runs on the same engine as ``SlideToConfirm/SlideToConfirm``, so it shares
labels, themes, haptics, async outcomes and accessibility. It fits where a track can't: a floating
corner, a card, a toolbar or a vertical bar item.

```swift
HoldToConfirmButton("Hold to send", systemImage: "paperplane.fill") {
    try await transfer.send()
}
.holdToConfirmProgressStyle(.ring)
.holdToConfirmCompletionStyle(.morph)
```

- **Hold**: the circle presses in under the finger, and after
  ``HoldToConfirmConfiguration/holdDelay`` the progress style starts; at the end it commits, plays the confirm haptic and runs the action.
- **Let go early**: progress drains back, or resets with ``HoldToConfirmReleaseBehavior/reset``.
  Pressing again during a drain resumes from where it is.
- **Slide off**: moving more than ``HoldToConfirmConfiguration/outsideTolerance`` outside the circle
  cancels.
- **Tap**: the circle pulses and shows ``SlideToConfirmLabels/tapHint``.

## Showing the hold

``HoldToConfirmProgressStyle`` offers ten styles. ``HoldToConfirmProgressStyle/ring`` and
``HoldToConfirmProgressStyle/segments`` give the most legible countdown; the fill styles
(``HoldToConfirmProgressStyle/fill``, ``HoldToConfirmProgressStyle/liquid``,
``HoldToConfirmProgressStyle/radial`` and ``HoldToConfirmProgressStyle/pie``) redraw the icon so
it changes color exactly where the fill reaches; ``HoldToConfirmProgressStyle/glow`` is the calmest;
``HoldToConfirmProgressStyle/countdown`` suits holds of three seconds or more.

## Celebrating success

``HoldToConfirmCompletionStyle`` offers six effects that play once the action returns. Each is a pure
function of one animatable value, so it renders deterministically in snapshots, and every one
settles straight to its final frame with Reduce Motion.

## Placing it within reach

A hold needs a resting thumb. ``ThumbReach`` models the natural, stretch and hard zones of a thumb on
a phone held in one hand, and every ``HoldToConfirmPlacement`` keeps the circle in the natural zone
of the hand it names. Placements name a hand rather than leading or trailing, because reach is
physical and doesn't mirror.

```swift
CheckoutScreen()
    .holdToConfirmOverlay(.thumbArc(.right)) {
        HoldToConfirmButton("Hold to pay", systemImage: "creditcard.fill") { try await pay() }
    }
```

Check a layout with ``ThumbReachOverlay``, or test a point with
``ThumbReach/zone(at:in:hand:)``.

## In a vertical bar

``HoldToConfirmConfiguration/verticalBar`` is a 48 pt ring that fits an ordinary item in a 56 pt
vertical bar, such as the trailing bar on iPhone Duo's outer display. It needs no extra height, so
it works where a 300 pt track can't get it. Put it in the tab zone with the tabs hidden, above the
tabs minimized to the current one, or just above the full tabs where the thumb wraps the edge. Keep
it in the lower half of the bar, and on the trailing hardware edge in every language.

## Topics

### Essentials

- ``HoldToConfirmButton``
- ``HoldToConfirmConfiguration``

### Styles

- ``HoldToConfirmProgressStyle``
- ``HoldToConfirmCompletionStyle``
- ``HoldToConfirmReleaseBehavior``
- ``HoldToConfirmLabelPosition``

### Placement

- ``HoldToConfirmPlacement``
- ``ThumbReach``
- ``ThumbReachOverlay``

### Previews and UIKit

- ``HoldToConfirmPreviewState``
- ``HoldToConfirmControl``
