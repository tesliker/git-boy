# Git Boy distribution launch

## Prepared locally

- Existing native macOS 14+ app and ad-hoc-signed ZIP (Apple silicon on the current build host).
- Electron Windows review preview, NSIS installer configuration, locked dependencies, real-Git tests, and Windows CI build workflow.
- GitHub bug and feature forms, contribution guidance, and preview build artifacts.
- Windows x64 NSIS installer built locally at `desktop/out/Git-Boy-Windows-0.4.0-alpha.1-x64.exe` (115 MB); not yet verified on Windows.
- Search-friendly static landing page with version/platform details, screenshots, privacy explanation, and honest availability labels.
- GitHub Pages workflow as a portable hosting option alongside the ChatGPT Site.

## Public repository and release process

Repository: https://github.com/tesliker/git-boy. MIT licensed, with Issues enabled. This public source tree starts with a fresh history and excludes proprietary-app inspection artifacts and private local research.

Run Preview builds, verify the Windows installer on a real Windows machine and the Mac ZIP on a second Mac, then attach verified artifacts and SHA-256 checksums to a prerelease. Keep untested artifacts explicitly experimental. Configure download links only after their release assets exist.

## Stores and signing

Direct downloads and GitHub Releases are the first route. Apple Developer ID signing and notarization are needed for a normal trusted Mac download; this Mac currently has no valid distribution-signing identity. Enrollment and signing credentials are owner actions. The Mac build is not yet a universal Intel/Apple-silicon binary.

Microsoft Store is a later channel: finish Windows QA, choose publisher identity, register/verify the account, and prepare the submission. Current Microsoft documentation says the new registration flow has no registration fee; identity verification still requires the owner. Do not create a store account or accept store agreements for the owner.

Sources checked October 22, 2026:
- https://docs.github.com/en/repositories/releasing-projects-on-github
- https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages
- https://developer.apple.com/developer-id/
- https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution
- https://learn.microsoft.com/en-us/windows/apps/publish/partner-center/open-a-developer-account
- https://www.electronjs.org/docs/latest/tutorial/security

## Windows preview scope

Open repository, status, full-row file selection, working/staged diffs, committed comparison, recent history, content-specific reading progress, explicit AI prompt copying, and gitboy protocol handling. Requires Git for Windows on PATH. No staging/commits/sync, conflict editing, or spotlight-tour parity yet. Link receiving asks before opening a repository; Node is isolated from the renderer and all content is rendered as text.

## Download Site

Published at https://git-boy.tesliker.chatgpt.site, with the Apple-silicon Mac preview ZIP and SHA-256 checksum. Windows is honestly marked in development until runtime QA. The downloadable page source is in `website/dist`; GitHub Pages is an optional mirror.

## Public launch update

GitHub CLI authorization is complete. Full sanitized source, issue templates, and preview build workflows are published on `tesliker/git-boy`. The first prerelease is https://github.com/tesliker/git-boy/releases/tag/v0.4.0-alpha.1 with Mac and Windows artifacts and SHA-256 checksums. The Windows executable is an unsigned experimental alpha; manual Windows runtime/install/uninstall QA remains open in issue #1. Trusted Mac signing/notarization remains issue #2. The public download page links to those release assets. GitHub Pages is enabled as an optional mirror.
