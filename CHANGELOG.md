# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-10-21

### Added

- `SlideToConfirm`, a SwiftUI control you can slide to the end or press and hold.
- Four hold behaviors: `combined` (recommended), `fill`, `glide` and `none`, plus hold-only mode.
- Three directions: `trailing` (mirrors in right-to-left layouts), `down` and `up`.
- Async actions with processing, success and failure states, `SlideToConfirmFailure` for custom
  failure text, and quiet cancellation with `CancellationError`.
- `SlideToConfirmConfiguration` covering interaction, timing, size, typography, knob, colors,
  motion and haptics, with `compact`, `large`, `verticalBar`, `slideOnly` and `holdOnly` presets.
- Themes: `standard`, `brand`, `accent`, `destructive`, `positive`, `monochrome`, `tinted(_:dark:)`
  and `onColor(_:)`, each with light and dark palettes, plus fully custom palettes.
- Custom knob content, SF Symbol icons and per-state labels localized into English, Arabic,
  French, German and Spanish.
- Haptics for every key moment, with system, disabled and custom handlers.
- Accessibility: a button for assistive technologies with an optional confirmation alert,
  keyboard activation, Dynamic Type growth and Reduce Motion support.
- Preview states for SwiftUI previews, galleries and snapshot tests.
- `SlideToConfirmControl`, a UIKit wrapper with target-action and Auto Layout sizing.
- A demo app with a showcase, eight real-world scenarios, a live playground and a states gallery.

[1.0.0]: https://github.com/mohamedsalahnassar/SlideToConfirm/releases/tag/1.0.0
