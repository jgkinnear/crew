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

A Developer ID certificate plus notarization is what makes double-click work without `xattr`.

## GitHub Actions

Pushes and pull requests build the Mac app on `macos-15`, run tests, and upload `Crew-mac-arm64.zip`. The workflow writes `.env` from GitHub Actions secrets, so the artifact can join the real room:

- `LIVEKIT_URL`
- `LIVEKIT_API_KEY`
- `LIVEKIT_API_SECRET`
- `LIVEKIT_ROOM`

Set those under the repo’s **Settings → Secrets and variables → Actions → Secrets**. They are not committed. The built zip still contains them, the same way a local `.env` is copied into the app.
