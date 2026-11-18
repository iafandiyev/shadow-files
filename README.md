# SHADOW FILES — iOS starter project

A native SwiftUI + RealityKit iOS prototype with a procedural compact city, third-person follow camera, touch movement, a simple evidence collection loop, local case-file persistence, a WebSocket multiplayer client, and a Vapor room server.

## Important scope note

This repository is a playable technical starter, not a finished AAA game. The city and detective avatar are generated from simple RealityKit meshes. There are no licensed AAA character/vehicle assets, facial animation system, full story campaign, weapon system, production identity/authentication, matchmaking service, or public hosting configured yet. The multiplayer server currently provides room creation/joining and message relay for connected room members; it keeps room state in memory and is not production hardened. The app's evidence notebook is locally persisted as JSON.

## Requirements

- Xcode 16 or later recommended
- iOS 17 or later
- Swift 5 language mode
- macOS with Xcode for local iOS builds
- Swift Package Manager for the Vapor backend

## iOS build

Open `SHADOWFILES.xcodeproj` in Xcode, select the `SHADOWFILES` scheme, choose an iPhone simulator or device, and build.

For a local unsigned device build:

```bash
xcodebuild \
  -project SHADOWFILES.xcodeproj \
  -scheme SHADOWFILES \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build
```

An unsigned IPA is a package of the app, not an install-ready signed app. Sign it with Sideloadly/AltStore or another legitimate signing workflow before installing it on an iPhone. A free Apple ID signing profile may need periodic renewal.

## GitHub Actions IPA build

The workflow `.github/workflows/ios-unsigned-ipa.yml` runs on GitHub-hosted `macos-latest` when code is pushed to `main` or `master`, and can also be started manually from the Actions tab.

After the workflow succeeds:

1. Open the repository on GitHub.
2. Select **Actions**.
3. Open **Build SHADOW FILES iOS IPA**.
4. Open the completed run.
5. Download the `SHADOW-FILES-unsigned-IPA` artifact.
6. Extract the artifact and sign the IPA with Sideloadly before installing it.

No paid Apple Developer account is required just to compile and package this unsigned IPA. App Store distribution and signing with a Developer certificate are separate.

## Run the multiplayer backend

In a terminal:

```bash
cd Backend
swift run
```

Default server endpoints:

- Health: `http://127.0.0.1:8080/health`
- WebSocket: `ws://127.0.0.1:8080/ws`

To listen on another port:

```bash
PORT=8080 HOST=0.0.0.0 swift run
```

When connecting from a physical iPhone on the same Wi-Fi network, replace `127.0.0.1` in the app with the computer's LAN IPv4 address, for example `ws://192.168.1.10:8080/ws`. The example IP is only illustrative; use the actual address of the computer running the server. Allow incoming connections through the computer's firewall.

For connections over the public internet, deploy the backend to a host and configure TLS/WSS (`wss://`). Do not expose the development server directly to the internet without authentication, TLS, rate limiting, and hardened validation.

## Backend tests

```bash
cd Backend
swift test
```

## Repository upload

Extract the ZIP, then double-click `upload-to-github.bat` on Windows. It clones the target repository, copies the project files into the clone, commits the changes, and pushes the current branch. Git for Windows and GitHub authentication are required. Review any existing repository files that may be overwritten before running it.

## Current playable features

- Native iOS app shell and dark detective menu
- Procedurally generated compact 3D Greywood block
- Third-person camera and simple on-screen movement control
- Search-area interaction and three evidence entries
- Case notebook and local JSON persistence
- WebSocket connection screen, room creation/join message flow, and server message relay
- GitHub Actions unsigned IPA packaging workflow
