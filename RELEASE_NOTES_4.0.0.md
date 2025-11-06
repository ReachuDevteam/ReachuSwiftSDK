# ReachuSwiftSDK 4.0.0

Major release with campaign model/decoding updates and new/updated UI components.

Breaking Changes
- Campaign model & decoding changes: introduce `ComponentResponse`, add `encode(to:)` to `AnyCodable`, adjust access levels. If you relied on internal types or extended decoding, re-check integrations.
- UI components updated to design‑system tokens and layouts; some initializers and default sizes may have changed (`RProductBanner`, `RProductCarousel`, `RProductStore`).

Features
- New: `RProductSpotlight` component with `componentId` support.
- `RProductBanner`: configurable styling (colors, sizes, overlay opacity) from backend; full URL resolution for relative images.
- `RProductCarousel`: page indicators; improved full‑layout sizing.
- `RProductStore`: better handling of `mode=all` with empty productIds.
- Logging: detailed decoding & product loading logs for easier debugging.

Fixes & Improvements
- Better WebSocket message handling; improved `RProductSlider` reactivity to campaign state.
- Show components even when no products found (empty states / banner without product).

Upgrade Notes
- Update SPM dependency to `from: "4.0.0"`.
- If you customize campaign decoding or UI components, validate assumptions against new models and initializers.

