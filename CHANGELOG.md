# Changelog

All notable changes to this project are documented in this file. This project follows Semantic Versioning.

## [2.0.0]

- Fix: Guard iOS‑only APIs for cross‑platform SwiftPM builds
  - Wrap `navigationBarHidden(_:)` with `#if os(iOS)`
  - Restrict `PresentationDetent` usage to iOS 16+ and iOS platform
  - Replace `UIImage` loading with `Image(name, bundle: .module)` in `RCheckoutOverlay`
- Docs: English documentation sweep across guides and README
- Infra: Remove GitHub Actions workflow; add local scripts
  - `scripts/ci_local.sh` for local build/test
  - `scripts/release_local.sh` for tagging and (optionally) creating releases

Notes: This release contains fixes and infrastructure/doc updates only. Public API surface is unchanged to the best of our knowledge.

## [1.0.0]

- First stable release of ReachuSwiftSDK
- Modular products:
  - ReachuCore, ReachuNetwork, ReachuDesignSystem, ReachuUI, ReachuLiveShow, ReachuLiveUI, ReachuComplete
- Demos extracted to external repository `ReachuSwiftSDK-Demos` and consume the SDK by SPM (version‑pinned)
- Platforms: iOS 15+, macOS 12+, tvOS 15+, watchOS 8+

