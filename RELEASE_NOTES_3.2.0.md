# ReachuSwiftSDK 3.2.0

Backward‑compatible features and fixes focused on Campaign components and UI behavior.

Features
- Auto‑configured campaign components: `RProductCarousel`, `RProductBanner`, `RProductStore` (63fd591)

Fixes & Improvements
- Improve WebSocket message handling and `RProductSlider` reactivity to campaign state (741a619)
- Fix `RProductCard` initialization (remove currency/country parameters) (d03fbe3)
- Fix `RProductBanner` colors (`surfaceSecondary`) and title usage (071aecc)
- Add detailed logging to `RProductSlider` for campaign state debugging (7582288)
- Docs: Kotlin migration guide for campaign features (b52dfc9)

Upgrade Notes
- No breaking changes from 3.1.0. Update your SPM dependency to `from: "3.2.0"`.
