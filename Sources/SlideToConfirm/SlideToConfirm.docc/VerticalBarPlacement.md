# Vertical bar placement

Let the control take a tab bar's place as a pull-down track on a vertical bar.

## Overview

Some layouts put the tab bar in a vertical bar on the trailing edge, under the thumb. On a task
screen such as Review, the tabs can step aside and the confirm control can take their zone as a
**pull-down** track. Holding works the same way: the knob glides down and the track fills behind it.

```swift
SlideToConfirm("Slide or hold to send") { try await send() }
    .slideToConfirmConfiguration(.verticalBar)   // .down, 56 pt wide
    .frame(height: 300)
```

## Guidelines

- **Same footprint as the tabs.** 56 pt wide, about 300 pt long and bottom-aligned, so it grows
  out of the space the tabs leave.
- **Pull down, don't push up.** The knob rests where the tabs began, inside easy reach. The drag
  never starts at the bottom edge, where an upward swipe means Home.
- **Same edge in every language.** The bar stays on the trailing hardware edge and down is down,
  so vertical tracks never mirror. Content mirrors as usual.
- **Portrait goes horizontal.** When the bars turn horizontal, use ``SlideToConfirmDirection/trailing``
  capped at 440 pt where the tab bar was.

## iPhone Duo

On iPhone Duo's outer display, put the control in a bottom toolbar item that prefers the vertical
axis, and hide the tab bar on the task screen. These APIs are new in iOS 27.1; confirm the exact
signatures in Xcode before shipping:

```swift
ReviewTransfer()
    .toolbarVisibility(.hidden, for: .tabBar)
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
