# Git Boy

A free, MIT-licensed Git client for human review of AI-generated code, with a vintage handheld-inspired interface.

**Download:** https://gitboy.app
**Bug reports and features:** https://github.com/tesliker/git-boy/issues

## Platforms

- **macOS:** native SwiftUI app, macOS 14+. Current download is Apple silicon, ad-hoc signed, not notarized. Includes diffs, staging/commits, branches/history, sync controls, conflict editing, spotlight help, AI prompt preview, and local review links.
- **Windows:** early Electron review preview. x64 NSIS installer builds; real Windows runtime QA is still required. Supports status, working/staged diffs, branch comparisons, history, review progress, AI prompt copy, and local protocol links. Git for Windows required. No staging, commits, sync, or conflict editor yet.

## Develop

Mac: `zsh scripts/build.sh`. See [QUICKSTART.md](QUICKSTART.md).

Windows review client:

```sh
cd desktop
npm ci
npm test
npm start
npm run dist:win
```

GitHub Actions builds both previews and attaches workflow artifacts. They are unsigned previews, not store releases. See [distribution notes](docs/DISTRIBUTION.md).

## Local AI and code review

Ask AI previews text for you to explicitly copy into Codex or ChatGPT; it does not call an AI model or automatically upload code. The optional read-only MCP bridge is `integration/bridge.mjs`. Local `gitboy://review` links need the repository on the computer opening them. They are not public code-sharing links.

## Contributing

Use the issue templates and see [CONTRIBUTING.md](CONTRIBUTING.md). Keep reports free of private code, tokens, and customer information. Git Boy uses system Git and existing local credentials. Never treat reading-progress markers as deployment authorization.

## License and credits

MIT; see [LICENSE](LICENSE). Original code and generated visual assets; no Tower code or bundled artwork is included. Independent project; not affiliated with Nintendo, Tower, OpenAI, or GitHub.
