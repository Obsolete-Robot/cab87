#!/usr/bin/env bash
set -euo pipefail

STEP_MARKER="::dispatch-step::"
SUBSTATUS_MARKER="::dispatch-substatus::"

say_step() {
  echo "${STEP_MARKER} $*"
}

say_sub() {
  echo "${SUBSTATUS_MARKER} $*"
}

LOCK_FILE="/tmp/cab87-deploy-dev.lock"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "Another cab87 deploy is already running; try again in a minute." >&2
  exit 1
fi

SOURCE_REPO="/srv/games/cab87-src"
REMOTE_URL="https://github.com/Obsolete-Robot/cab87.git"
BRANCH="main"
EXPORT_DIR="${SOURCE_REPO}/export"
DEPLOY_DIR="/srv/games/cab87"
GODOT_BIN="/home/david/.local/bin/godot"
PUBLIC_URL="https://dev.obsoleterobot.com/cab87/"
DEPLOY_LABEL="cab87:deploy-dev"

say_step "Preparing deploy"
[[ -x "$GODOT_BIN" ]] || { echo "Missing Godot binary: $GODOT_BIN" >&2; exit 1; }

if [[ ! -d "${SOURCE_REPO}/.git" ]]; then
  say_step "Initializing source mirror"
  mkdir -p /srv/games
  git clone "$REMOTE_URL" "$SOURCE_REPO"
fi

say_step "Syncing latest ${BRANCH} from origin"
git -C "$SOURCE_REPO" fetch origin "$BRANCH"
git -C "$SOURCE_REPO" checkout -q "$BRANCH"
git -C "$SOURCE_REPO" reset --hard FETCH_HEAD >/dev/null
git -C "$SOURCE_REPO" clean -fd >/dev/null

COMMIT_SHORT="$(git -C "$SOURCE_REPO" rev-parse --short=8 HEAD)"
TIMECODE="$(date +"%Y.%m.%d-%H:%M")"
say_sub "Source commit: ${COMMIT_SHORT}"

say_step "Exporting Godot web build"
mkdir -p "$EXPORT_DIR"
"$GODOT_BIN" --path "$SOURCE_REPO" --headless --export-release "Web" "$EXPORT_DIR/index.html"

say_step "Syncing files to deploy directory"
mkdir -p "$DEPLOY_DIR"
rsync -av --delete "$EXPORT_DIR/" "$DEPLOY_DIR/" >/dev/null
chgrp -R gamedev "$DEPLOY_DIR"
chmod -R g+w "$DEPLOY_DIR"

say_step "Running smoke checks"
status="$(curl -o /dev/null -s -w '%{http_code}' "$PUBLIC_URL")"
if [[ "$status" != "200" ]]; then
  echo "Public URL check failed (expected 200, got $status): $PUBLIC_URL" >&2
  exit 1
fi

local_sha="$(sha256sum "$DEPLOY_DIR/index.pck" | awk '{print $1}')"
remote_sha="$(curl -fsSL "${PUBLIC_URL}index.pck" | sha256sum | awk '{print $1}')"
if [[ "$local_sha" != "$remote_sha" ]]; then
  echo "SHA mismatch for index.pck (local != remote)" >&2
  exit 1
fi

say_sub "${DEPLOY_LABEL} 🔗 ${PUBLIC_URL}"
cat <<EOF
${DEPLOY_LABEL} 🔗 ${PUBLIC_URL}
✅ LIVE: ${PUBLIC_URL}
✅ BUILD: dev ${TIMECODE} ${COMMIT_SHORT}
EOF
