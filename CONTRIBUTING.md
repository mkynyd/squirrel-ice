# Contributing

Thanks for improving WuSong IME. This project combines a macOS input method frontend, bundled Rime configuration, native UI code, and release packaging, so small, well-scoped changes are easiest to review.

## Development Setup

```bash
brew install cmake boost capnp leveldb
make prepare
make debug
```

Use `./script/build_and_run.sh --verify` when you need to build, launch, and confirm the local app process starts.

## Pull Request Checklist

- Keep changes focused on one behavior, UI area, or packaging concern.
- Update `README.md`, `README.en.md`, or `BUILD.md` when user-facing behavior changes.
- Preserve upstream license notices for Squirrel, rime-ice, librime, Sparkle, and plum.
- Run the narrowest useful build or test command before opening a pull request.
- Include screenshots for visible UI changes.

## Commit Style

Prefer concise conventional prefixes:

- `feat:` for user-facing features
- `fix:` for bug fixes
- `docs:` for documentation-only changes
- `build:` for packaging, signing, CI, or build scripts
- `chore:` for maintenance
