# Changelog

All notable changes to this project are documented in this file. This project follows Semantic Versioning.

## [3.2.0]

Features
- Auto‑configured campaign components: `RProductCarousel`, `RProductBanner`, `RProductStore` (63fd591)

Fixes & Improvements
- Improve WebSocket message handling and `RProductSlider` reactivity to campaign state (741a619)
- Fix `RProductCard` initialization (remove currency/country params) (d03fbe3)
- Fix `RProductBanner` colors and title usage (071aecc)
- Add detailed logging to `RProductSlider` for campaign state debugging (7582288)
- Docs: Kotlin migration guide for campaign features (b52dfc9)

Notes: Backward‑compatible minor release (builds on 3.1.0 campaign configuration).

## [3.1.0]

Features
- feat: Make campaign endpoints configurable from JSON config file (e2484f1)
- feat: Fix campaign endpoints and improve market availability check (4c78d73)

Fixes
- fix: Adjust cart indicator size and remove badge shadow (f24c4d4)

Merges
- Merge pull request #16: feature/campaign-integration (df7517a)

Notes: Backward‑compatible improvements; minor version bump.

## [3.0.0]

- Docs: Update installation snippet to `from: "3.0.0"`
- Demos: Pin example projects to ReachuSwiftSDK `3.0.0`
- Notes: No functional changes over 2.0.0; version bump for alignment across repos and documentation.

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
