# Git Boy Windows preview

This is a separate Electron review client, not a replacement for the native Mac app. Requires Node 24+ for development and Git on PATH. End users need Git for Windows; Electron supplies its own runtime.

```sh
npm ci
npm test
npm start
npm run dist:win
```

Build on a Windows runner for the supported installer path. CI uploads an unsigned NSIS preview installer; it does not publish a release. Verify it on a real Windows machine before distribution.

Implemented: repository status, staged/working diffs, branch comparison, history, full-row file selection, reading progress, AI prompt preview/copy, and confirmed local protocol links. No write operations or conflict editor yet. The local repo path in a link must exist on the computer opening it.
