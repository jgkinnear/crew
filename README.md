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
