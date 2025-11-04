#!/usr/bin/env bash
set -euo pipefail

if [[ ${1:-} == "" ]]; then
  echo "Usage: scripts/release_local.sh vX.Y.Z [--no-ci] [--push-origin] [--notes-file path/to/notes.md]"
  exit 1
fi

TAG="$1"
RUN_CI=true
PUSH_ORIGIN=false
NOTES_FILE=""

shift || true
while [[ ${1:-} != "" ]]; do
  case "$1" in
    --no-ci) RUN_CI=false ;;
    --push-origin) PUSH_ORIGIN=true ;;
    --notes-file)
      shift
      NOTES_FILE="${1:-}"
      if [[ -z "$NOTES_FILE" || ! -f "$NOTES_FILE" ]]; then
        echo "[release] --notes-file requires a valid file path"
        exit 1
      fi
      ;;
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
  if [[ -n "$NOTES_FILE" ]]; then
    gh release create "$TAG" -t "ReachuSwiftSDK $TAG" -F "$NOTES_FILE"
  else
    gh release create "$TAG" -t "ReachuSwiftSDK $TAG" -n "Release $TAG"
  fi
else
  cat <<EOF
[release] GitHub CLI not found. Create the Release via the GitHub UI:
  1) Go to your repository → Releases → Draft a new release
  2) Choose tag: $TAG
  3) Title: ReachuSwiftSDK $TAG
  4) Add release notes and publish

Or use the API with curl (requires GITHUB_TOKEN):
  curl -H "Authorization: Bearer \$GITHUB_TOKEN" \\
       -H "Accept: application/vnd.github+json" \\
       -X POST \\
       https://api.github.com/repos/ReachuDevteam/ReachuSwiftSDK/releases \\
       -d @- <<JSON\n{\n  "tag_name": "$TAG",\n  "name": "ReachuSwiftSDK $TAG",\n  "body": "$( [[ -n "$NOTES_FILE" ]] && sed 's/"/\\"/g' "$NOTES_FILE" | awk 'BEGIN{ORS="\\n"}{print}' || echo "Release $TAG" )",\n  "draft": false,\n  "prerelease": false\n}\nJSON
EOF
fi

echo "[release] Done"
