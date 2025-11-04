% Releasing (SDK)

This document summarizes the recommended flow to publish new versions of `ReachuSwiftSDK` and how to pin them in demos.

## Pre‑release checklist
- Build and test:
  - `swift build --configuration release`
  - `swift test`
- Update `CHANGELOG.md` (if applicable) with changes and notes.
- Ensure `Package.swift` exports the right products.

## Create and push a SemVer tag
1. Choose version (SemVer):
   - Patch: internal fixes, no API break → `vX.Y.Z+1`
   - Minor: new compatible features → `vX.Y+1.0`
   - Major: breaking changes → `vX+1.0.0`
2. Create annotated tag and push:
   - `git tag -a v1.0.0 -m "ReachuSwiftSDK 1.0.0"`
   - `git push origin v1.0.0`

> SPM detects versions via tags in the form `vX.Y.Z`. A GitHub Release is optional but recommended.

## GitHub Release (optional)
- UI: “Draft a new release” → select tag `vX.Y.Z` → add notes.
- CLI (GitHub CLI):
  - `gh release create v1.0.0 -t "ReachuSwiftSDK 1.0.0" -n "Release notes"`

## Consuming the version from demos
- In `ReachuSwiftSDK-Demos`, for each Xcode demo:
  - Package Dependencies → Add: `https://github.com/TU_ORG/ReachuSwiftSDK.git`
  - Version rule:
    - “Exact 1.0.0” to pin strictly.
    - “From 1.0.0” to allow compatible updates.
- In SPM demos (`Package.swift`):
```swift
.package(url: "https://github.com/TU_ORG/ReachuSwiftSDK.git", exact: "1.0.0")
```

## Best practices
- Keep `main` stable; use feature branches.
- Release frequently but with tested changes.
- Document breaking changes in `CHANGELOG.md` and the Release.
- Consider macOS CI to run `swift build`/`swift test` on PRs and `main`.
