# Customization

Change interaction, timing, size, typography, knob, colors and motion.

## Set a configuration

Every option lives in ``SlideToConfirmConfiguration``. Set one for a view hierarchy, or adjust the
inherited one:

```swift
SlideToConfirm("Hold to delete") { try await account.delete() }
    .slideToConfirmConfiguration {
        $0.holdBehavior = .fill
        $0.holdDuration = 2
        $0.theme = .destructive
        $0.icons.idle = .systemImage("trash.fill")
    }
```

Start from a preset with ``SlideToConfirmConfiguration/with(_:)``:

```swift
.slideToConfirmConfiguration(.compact.with { $0.theme = .positive })
```

Presets: ``SlideToConfirmConfiguration/compact``, ``SlideToConfirmConfiguration/large``,
``SlideToConfirmConfiguration/verticalBar``, ``SlideToConfirmConfiguration/slideOnly`` and
``SlideToConfirmConfiguration/holdOnly``.

## Choose a hold behavior

| Behavior | While holding |
| --- | --- |
| ``SlideToConfirmHoldBehavior/combined`` | The knob glides and a solid fill follows it. Recommended. |
| ``SlideToConfirmHoldBehavior/fill`` | The knob stays put and the track fills. The calmest option. |
| ``SlideToConfirmHoldBehavior/glide`` | The knob glides with the soft drag fill. |
| ``SlideToConfirmHoldBehavior/none`` | Nothing. Slide only. |

Turn off ``SlideToConfirmConfiguration/allowsDragging`` for a hold-only control.

## Pick colors

Built-in themes adapt to light and dark appearance:
``SlideToConfirmTheme/standard``, ``SlideToConfirmTheme/accent``, ``SlideToConfirmTheme/positive``,
``SlideToConfirmTheme/destructive``, ``SlideToConfirmTheme/monochrome`` and
``SlideToConfirmTheme/brand``. Build one from any color with
``SlideToConfirmTheme/tinted(_:dark:)``, or for colored surfaces with
``SlideToConfirmTheme/onColor(_:)``. For full control, edit a ``SlideToConfirmPalette``:

```swift
var light = SlideToConfirmPalette.light(accent: .indigo)
light.success = .mint
let theme = SlideToConfirmTheme(light: light, dark: .dark(accent: .indigo))
```

## Replace the knob icon

Use ``SlideToConfirmIcons`` for SF Symbols, or draw your own view:

```swift
.slideToConfirmKnob { knob in
    Image(systemName: knob.state.phase == .success ? "lock.open.fill" : "lock.fill")
        .foregroundStyle(knob.iconColor)
}
```

## Observe progress

```swift
.onSlideToConfirmStateChange { state in
    doorOpenness = state.progress
}
```

## Freeze a state for previews

```swift
#Preview {
    SlideToConfirm("Slide or hold to send") {}
        .slideToConfirmPreviewState(.holding(progress: 0.6))
}
```
