# Contributing

Thanks for helping make SlideToConfirm better. Bug reports, ideas and pull requests are all welcome.

## Getting set up

```sh
git clone https://github.com/mohamedsalahnassar/SlideToConfirm.git
cd SlideToConfirm
open Package.swift                              # the library
open Example/SlideToConfirmDemo.xcodeproj       # the demo app, using the local package
```

You need Xcode 15 or later. The demo app targets iOS 17.

## How the code is organized

| Path | What lives there |
| --- | --- |
| `Sources/SlideToConfirm/Engine` | The interaction model: a pure value type with no UI or clock. Every gesture, timer and outcome goes through `ConfirmEngine`. |
| `Sources/SlideToConfirm/Views` | The SwiftUI control, the track renderer, knob icons and effects. |
| `Sources/SlideToConfirm/Configuration` | Public configuration, themes, labels, icons and haptics. |
| `Sources/SlideToConfirm/UIKit` | `SlideToConfirmControl`. |
| `Tests/SlideToConfirmTests` | Engine and layout tests (run everywhere), rendering tests (Apple platforms) and the README image renderer. |
| `Example` | The demo app and its UI tests. |

Behavior changes almost always start in `ConfirmEngine`. Because it never reads the clock, you can
test any timing precisely: pass times in, assert on the updates that come out.

## Before you open a pull request

```sh
swift test                                                       # engine + layout + rendering
xcodebuild test -scheme SlideToConfirm \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'       # same tests on iOS
xcodebuild test -project Example/SlideToConfirmDemo.xcodeproj \
  -scheme SlideToConfirmDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'       # UI tests with real touches
```

- Add or update tests for any behavior change.
- Check light, dark and right-to-left for visual changes, and attach before and after screenshots.
- Keep public API documented with `///` comments; they power the DocC reference.
- New labels need entries in every `Resources/*.lproj/Localizable.strings` file.

## Regenerating README images

The images in `docs/` are produced by CI from the real control. Run the **Screenshots** workflow
from the Actions tab, or include `[screenshots]` in a commit message, and the workflow commits
fresh images to your branch.

## Code of conduct

Be kind and assume good intent. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
