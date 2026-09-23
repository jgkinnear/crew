# Crew

Native macOS huddle for a small team: persistent voice room, screen share, and collaborative pointers/annotations over LiveKit.

## Setup

1. Copy `.env.example` to `.env` and fill in LiveKit Cloud (or local) credentials.
2. Open `Crew.xcodeproj` in Xcode and run the **Crew** scheme.

The build copies `.env` into the app bundle. `.env` is gitignored; the shipped app can still carry credentials.

Requires macOS 14+, Apple Silicon for a default arm64 build.

## Share with the team

```bash
./scripts/share-mac.sh
```

That produces `release/Crew-mac-arm64.zip`. Recipients:

1. Unzip and drag `Crew.app` to `/Applications`
2. Run `xattr -cr /Applications/Crew.app` once (unsigned / ad-hoc signed)
3. Open Crew, allow Microphone and Screen Recording when asked

A Developer ID certificate plus notarization is what makes double-click work without `xattr`. After that first launch, Crew checks for a newer build on startup, asks, then replaces itself and relaunches.

## GitHub Actions

Pushes and pull requests build the Mac app on `macos-15`, run tests, and upload `Crew-mac-arm64.zip`. Pushes to `master` also publish that zip to the private `updates` release, which installed copies download.

The workflow writes `.env` from GitHub Actions secrets:

- `LIVEKIT_URL`
- `LIVEKIT_API_KEY`
- `LIVEKIT_API_SECRET`
- `LIVEKIT_ROOM`
- `CREW_UPDATE_TOKEN` — fine-grained personal access token, this repo only, Contents: Read
- `SPARKLE_ED25519_KEY` — Sparkle update signing key

Set those under the repo’s **Settings → Secrets and variables → Actions → Secrets**. They are not committed. The built zip still contains the LiveKit settings and the update token, the same way a local `.env` is copied into the app.
