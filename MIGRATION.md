# Migration Guide

This guide covers key changes when upgrading between recent major versions of ReachuSwiftSDK.

## 3.x → 4.0.0

4.0.0 introduces updates to campaign models/decoding and UI components. Most apps can upgrade with minimal changes, but validate the following:

### Campaign Models & Decoding
- New `ComponentResponse` model used to decode campaign components.
- `AnyCodable` adds `encode(to:)` and access levels updated.
- If you had custom decoding or extended internal types, revisit those extensions against the new models.

Recommendation:
- Prefer the high-level components/APIs instead of decoding campaign payloads yourself.
- If you must decode, use the public models exported by ReachuCore.

### UI Components
- Components have been aligned with the design system (colors, shadows, border radius) and may have small size/layout adjustments.
- Some initializers added/adjusted to remove redundant params or follow config-driven styles.

Notable components:
- `RProductBanner`:
  - Styles (colors, sizes, overlay opacity) now configurable via backend/config.
  - Relative image URLs are resolved using `restAPIBaseURL`.
- `RProductCarousel`:
  - Page indicators added.
  - Improved full-layout card sizing.
- `RProductStore`:
  - Handles `mode=all` even when `productIds` is empty and shows empty states.
- `RProductSpotlight` (new):
  - Supports `componentId` to load spotlight product from campaign.

### WebSocket & Slider Reactivity
- Improved message handling and `RProductSlider` response to campaign state.

### Configuration
- Campaign endpoints configurable via JSON (`campaigns.webSocketBaseURL`, `campaigns.restAPIBaseURL`).
- Ensure your app’s `reachu-config.json` includes proper values.

### Quick Checklist
- Bump SPM dependency to `from: "4.0.0"`.
- Verify campaign configuration and product components render correctly.
- If extending decoding/UI, validate any type/initializer assumptions.

