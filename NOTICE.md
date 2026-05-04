# Notices

This repository is a macOS input method distribution built from several open source projects. The root project is distributed under GPL-3.0. Bundled third-party components keep their original copyright notices and license terms.

This file is a practical inventory for release packaging. It is not legal advice.

## Root Project

- Project: WuSong IME / squirrel-ice
- License: GNU General Public License v3.0
- License file: [LICENSE](LICENSE)

## Bundled And Derived Components

| Component | Purpose | License file |
| --- | --- | --- |
| Squirrel | macOS Rime input method frontend | [squirrel/LICENSE.txt](squirrel/LICENSE.txt) |
| rime-ice | Bundled Rime configuration, dictionaries, schemas, Lua scripts, and OpenCC data | [vendor/rime-ice/LICENSE](vendor/rime-ice/LICENSE) |
| librime | Rime core input method engine | [squirrel/librime/LICENSE](squirrel/librime/LICENSE) |
| Sparkle | macOS update framework | [squirrel/Sparkle/LICENSE](squirrel/Sparkle/LICENSE) |
| plum | Rime configuration package helper | [squirrel/plum/LICENSE](squirrel/plum/LICENSE) |

## Distribution Notes

- Keep the root `LICENSE` file with any source or binary distribution.
- Keep the license files listed above when redistributing bundled third-party source or binary artifacts.
- Mark modified versions clearly in release notes or source history.
- When distributing binaries covered by GPL-3.0, provide the corresponding source code in the manner required by that license.
- Do not imply endorsement by upstream projects unless explicit permission has been granted.
