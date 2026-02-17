# Demo Brand Variants

**Demo only.** This folder contains brand-specific demo configurations for the Viaplay demo app.

## Usage

Edit `Configuration/demo-config.json` and change `"active"` to switch demos. Then press Play.

| active value | Demo data | Reachu config (theme/brand) |
|--------------|-----------|-----------------------------|
| `elkjop` | `brands/elkjop/elkjop-demo-static-data.json` | `reachu-config.json` (default) |
| `brand2` | `brands/brand2/brand2-demo-static-data.json` | `reachu-config.json` (default) |
| `power` | `brands/power/power-demo-static-data.json` | `brands/power/reachu-config-power.json` |
| `skistar` | `brands/skistar/skistar-demo-static-data.json` | `brands/skistar/reachu-config-skistar.json` |
| (omit or invalid) | `Configuration/demo-static-data.json` | `reachu-config.json` |

**Override:** `REACHU_DEMO_BRAND` env var (e.g. in scheme) takes precedence over demo-config.json.

## Adding a New Brand

1. Create a folder `brands/<brand-name>/`
2. Add `<brand>-demo-static-data.json` (copy from `brands/elkjop/elkjop-demo-static-data.json` and customize)
3. (Optional) Add `reachu-config-<brand>.json` for brand-specific theme/colors (e.g. Power orange, SkiStar red)
4. Add brand-specific images to `Assets.xcassets` and reference them in the JSON
5. Set `REACHU_DEMO_BRAND=<brand-name>` when running, or edit `demo-config.json` `active`
