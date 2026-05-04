# WuSong IME

**Language: [中文](README.md) | English**

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-555.svg)](BUILD.md)
[![Native macOS](https://img.shields.io/badge/UI-AppKit%20%2B%20SwiftUI-0A84FF.svg)](squirrel/sources)

WuSong IME is a native macOS distribution of Rime. It packages the [Squirrel](https://github.com/rime/squirrel) macOS input method frontend with the [rime-ice](https://github.com/iDvel/rime-ice) Pinyin configuration, so users get a ready-to-use installer, bundled dictionaries, a native settings panel, and theme management without manually deploying YAML files.

The goal is simple: keep Rime transparent, configurable, and fast, while making the first install and everyday maintenance much easier on macOS.

## Features

- **Ready to use**: Bundled rime-ice configuration, dictionaries, Lua scripts, and OpenCC data
- **Native settings panel**: Manage themes, dictionaries, schemas, keyboard layout, and candidate window style with SwiftUI
- **Theme system**: Built-in macOS Light, macOS Dark, and WeChat-style themes, with custom colors and live preview
- **Hot deployment**: Configuration changes notify the input method to redeploy without a manual restart
- **Rime ecosystem compatible**: YAML configuration, user dictionaries, schemas, and OpenCC data stay compatible with the Rime workflow
- **Lightweight architecture**: No Electron or Chromium; candidate rendering and settings use native macOS technologies

## Screenshots

The repository does not yet include final screenshots. Recommended release assets:

- Candidate window in light and dark themes
- Settings panel for theme, dictionary, and schema management
- The installed input method in macOS system settings

## Requirements

- macOS 13.0 Ventura or later
- Apple Silicon or Intel Mac
- Xcode 14 or later for local builds

## Quick Start

```bash
git clone https://github.com/mkynyd/squirrel-ice.git
cd squirrel-ice

# Prepare source files and bundled data
make prepare

# Build Debug, arm64 by default
make debug

# Build Release and create a pkg, arm64 by default
make package

# Optional: build a universal binary after dependencies are also universal
make package-universal
```

Build artifacts:

- `squirrel/build/Build/Products/Debug/Squirrel.app`
- `squirrel/build/Build/Products/Release/Squirrel.app`
- `squirrel/package/Squirrel.pkg`

See [BUILD.md](BUILD.md) for full build, signing, and notarization notes.

## Dependencies

```bash
brew install cmake boost capnp leveldb
```

For a signed release package, prepare an Apple Developer ID certificate and set:

```bash
export DEV_ID="Developer ID Application: Your Name (TEAMID)"
make package
```

The default package target builds `arm64`. To ship Intel support as well, make sure librime, Sparkle, and related plugins are universal binaries, then run `make package-universal`.

## Tech Stack

| Layer | Technology | Purpose |
| --- | --- | --- |
| Input method frontend | Squirrel, Swift, AppKit | macOS Input Method Kit, candidate window, key handling |
| Settings UI | SwiftUI | Graphical configuration, theme preview, preferences |
| Core engine | librime, C++ | Pinyin segmentation, dictionary lookup, ranking, user dictionary |
| Configuration | YAML | Standard Rime format for portability and debugging |
| Extensions | librime-lua, OpenCC | Lua extensions, character conversion, output processing |
| Updates | Sparkle 2 | Standard macOS app update framework |

## Feature Status

| Feature | Status |
| --- | --- |
| Theme switching and live preview | Implemented |
| Custom theme colors | Implemented |
| Dictionary enable and disable controls | Implemented |
| Double Pinyin schema selection | Implemented |
| English keyboard layout selection | Implemented |
| Candidate font size and orientation | Implemented |
| User dictionary shortcut | Implemented |
| Mixed Chinese and English input | Implemented |
| Traditional Chinese output | Implemented |
| Symbols, date, calculator, Unicode, and other extensions | Implemented |
| Configuration hot deployment | Implemented |
| Sparkle update framework | Integrated |

## Repository Layout

```text
squirrel-ice/
├── README.md                 # Chinese README
├── README.en.md              # English README
├── BUILD.md                  # Build, signing, and packaging guide
├── LICENSE                   # Root project license
├── NOTICE.md                 # Third-party notices
├── Makefile                  # Root build entrypoint
├── script/build_and_run.sh   # Local build and launch helper
├── scripts/bootstrap_sources.sh
├── squirrel/                 # Customized Squirrel input method
│   ├── Squirrel.xcodeproj/
│   ├── sources/              # Swift and AppKit/SwiftUI sources
│   ├── data/                 # Bundled Rime configuration and assets
│   ├── themes/               # Built-in themes
│   ├── librime/              # Rime core engine
│   ├── plum/                 # Rime package management helper
│   └── Sparkle/              # Update framework
└── vendor/rime-ice/          # Upstream rime-ice reference copy
```

## Configuration Directory

On first launch, bundled configuration is deployed to:

```text
~/Library/Rime/
├── .wusong_version
├── squirrel.custom.yaml
├── default.custom.yaml
├── rime_ice.dict.custom.yaml
├── cn_dicts/
├── en_dicts/
├── lua/
├── opencc/
└── themes/
```

Users can keep editing YAML files directly, or use the settings panel for common tasks.

## Development Commands

```bash
# Fast local build
make debug

# Build and launch the local app
./script/build_and_run.sh

# Build Release and launch
./script/build_and_run.sh --release

# Build, launch, and verify the process exists
./script/build_and_run.sh --verify
```

## Release Checklist

- [ ] `make package` generates `squirrel/package/Squirrel.pkg`
- [ ] App and pkg are signed with Developer ID
- [ ] The pkg is notarized and passes Gatekeeper validation
- [ ] For universal releases, librime, Sparkle, and plugins include both `arm64` and `x86_64`
- [ ] README screenshots, version number, changelog, and release notes are current
- [ ] Release artifacts include `LICENSE` and required third-party notices

## Upstream Projects

This project builds on:

- [rime/squirrel](https://github.com/rime/squirrel)
- [iDvel/rime-ice](https://github.com/iDvel/rime-ice)
- [rime/librime](https://github.com/rime/librime)
- [sparkle-project/Sparkle](https://github.com/sparkle-project/Sparkle)

## License

The root project is licensed under the [GNU General Public License v3.0](LICENSE). Some third-party components keep their original licenses and copyright notices. See [NOTICE.md](NOTICE.md) and the `LICENSE` files in each bundled subdirectory.

If you distribute a modified version or binary package, keep the applicable license texts and copyright notices, and comply with GPL-3.0 source availability and modification notice requirements.
