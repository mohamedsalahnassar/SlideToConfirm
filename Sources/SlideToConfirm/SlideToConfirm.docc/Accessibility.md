# Accessibility

How the control works with assistive technologies, the keyboard, Dynamic Type and Reduce Motion.

## Assistive technologies get a button

VoiceOver, Switch Control and Voice Control see one button named after the idle label, with the
hint "Double-tap to confirm." Activating it snaps the knob to the end and runs the action.
Name the action, not the gesture:

```swift
SlideToConfirm("Slide or hold to send") { try await send() }
    .accessibilityLabel("Send AED 2,500 to Sara Ahmed")
```

For money and other consequential actions, add a second step:

```swift
.slideToConfirmAccessibilityAlert(
    "Send AED 2,500 to Sara Ahmed?",
    message: "The money arrives today, within minutes."
)
```

The alert appears only for assistive technologies. Touch and keyboard confirmations are unchanged.

## Keyboard

On iOS 17, iPadOS 17 and macOS 14 or later, the control can take keyboard focus. Return or Space
confirms.

## Dynamic Type

The label follows the person's text size up to
``SlideToConfirmConfiguration/maximumDynamicTypeSize``. At accessibility sizes the track grows to
fit, and never shrinks below ``SlideToConfirmConfiguration/thickness``.

## Reduce Motion

With Reduce Motion on, the shimmer stops, springs lose their overshoot and the failure shake is
skipped. The glide and fill still run because they carry meaning.

## Server truth

The control turns green only after your action returns, stays locked from commit until then, and
announces processing, success and failure through its accessibility value.
