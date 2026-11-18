# SHADOW FILES v1.0 — iOS Detective Game

A native SwiftUI + RealityKit iOS detective game foundation with a compact procedural 3D city, third-person movement/camera, three playable evidence cases, interrogation decisions, local save data, and room-code WebSocket multiplayer (2–8 players) backed by a Swift/Vapor server.

## What v1.0 includes

- Native iOS app, Swift 5 language mode, iOS 17 minimum
- RealityKit non-AR 3D city scene built from iOS 17-compatible meshes
- Third-person follow camera, joystick movement, camera drag, remote detective avatars
- Three missions: The Empty Apartment, Blood on the Docks, The Last Witness
- Evidence markers placed in the world; clues are collected by approaching the correct marker
- Case notebook, interrogation choices, case completion, mission unlocks
- JSON persistence in Application Support
- WebSocket room creation/joining, 8-player room cap, player position relay, chat relay
- Vapor backend with `/health` and `/ws`
- GitHub Actions workflows for unsigned IPA packaging and backend tests
- Windows upload script for the repository `iafandiyev/shadow-files`

## Important limits

This is a complete playable v1.0 indie prototype, not a commercial AAA production. The city and detective avatars are original procedural geometry; high-detail human/vehicle models, motion-captured animation, voice chat, matchmaking accounts, persistent public hosting, and a large authored campaign are not included. The multiplayer backend must be deployed separately to a reachable host. It is not hosted by GitHub Actions. The room server is a prototype relay and should be hardened with authentication, TLS, abuse controls, and persistent storage before public release.

An unsigned IPA can be built for free with GitHub Actions. It is not installable until it is signed through Sideloadly/AltStore or another signing method. A free Apple ID signing profile usually needs periodic renewal.

## Build iOS IPA with GitHub Actions

1. Push this project to the repository's `main` branch.
2. Open **Actions** in GitHub.
3. Select **Build SHADOW FILES iOS IPA**.
4. Wait for the workflow to complete.
5. Download artifact `SHADOW-FILES-unsigned-IPA`.
6. Extract it and sign the IPA with Sideloadly before installing it on an iPhone.

The workflow uses `macos-latest`, `xcodebuild`, `CODE_SIGNING_ALLOWED=NO`, and creates `Payload/SHADOWFILES.app` inside an IPA archive.

## Run the iOS app locally

Open `SHADOWFILES.xcodeproj` on a Mac with Xcode 16 or later. Select the `SHADOWFILES` scheme and an iPhone simulator/device, then Build/Run. The app requires iOS 17 or later.

## Run the multiplayer server

Requirements: macOS or Linux, Swift 5.9+, internet access for Swift Package Manager dependency resolution.

```bash
cd Backend
swift run
```

Default endpoints:

- Health check: `http://127.0.0.1:8080/health`
- WebSocket: `ws://127.0.0.1:8080/ws`

When testing on a physical iPhone on the same Wi-Fi network, set the app's server URL to the computer's LAN address, for example `ws://192.168.1.20:8080/ws` (replace the example IP with the computer's real LAN IP). Allow incoming connections in the computer firewall.

For internet multiplayer, deploy the backend to a public host and configure `wss://` behind TLS. Do not expose the development server publicly without adding account authentication, TLS termination, rate limiting, abuse monitoring, and persistent storage.

## Windows: upload this folder to GitHub

1. Extract the ZIP.
2. Install Git for Windows if `git` is unavailable.
3. Run `upload-to-github.bat` from the extracted folder.
4. Authenticate with GitHub when Git requests it.
5. Open the Actions tab to monitor the build.

The upload script clones the existing repository before copying the project so the current `main` history is preserved. It does not delete `.git` or build the project locally.
