#!/usr/bin/env bash
set -euo pipefail

if [[ ${1:-} == "" ]]; then
  echo "Usage: scripts/release_local.sh vX.Y.Z [--no-ci] [--push-origin]"
  exit 1
fi

TAG="$1"
RUN_CI=true
PUSH_ORIGIN=false

shift || true
while [[ ${1:-} != "" ]]; do
  case "$1" in
    --no-ci) RUN_CI=false ;;
    --push-origin) PUSH_ORIGIN=true ;;
    *) echo "Unknown option: $1" ; exit 1 ;;
  esac
  shift || true
done

if [[ $RUN_CI == true ]]; then
  echo "[release] Running local CI checks"
  "$(dirname "$0")/ci_local.sh"
fi

echo "[release] Checking git status"
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "[release] Working tree not clean. Commit or stash changes before releasing."
  exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "[release] Current branch: $CURRENT_BRANCH"

echo "[release] Creating annotated tag: $TAG"
git tag -a "$TAG" -m "ReachuSwiftSDK $TAG" || {
  echo "[release] Tag $TAG may already exist. Use a new version or delete the tag."
  exit 1
}

if [[ $PUSH_ORIGIN == true ]]; then
  echo "[release] Pushing tag to origin"
  git push origin "$TAG"
else
  echo "[release] Skipping push. To push: git push origin $TAG"
fi

if command -v gh >/dev/null 2>&1; then
  echo "[release] Creating GitHub Release via gh CLI"
  gh release create "$TAG" -t "ReachuSwiftSDK $TAG" -n "Release $TAG"
else
  cat <<EOF
[release] GitHub CLI not found. Create the Release via the GitHub UI:
  1) Go to your repository → Releases → Draft a new release
  2) Choose tag: $TAG
  3) Title: ReachuSwiftSDK $TAG
  4) Add release notes and publish
EOF
fi

echo "[release] Done"

